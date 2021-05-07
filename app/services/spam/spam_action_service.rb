# frozen_string_literal: true

module Spam
  class SpamActionService
    include SpamConstants

    ##
    # Utility method to filter SpamParams from parameters, which will later be passed to #execute
    # after the spammable is created/updated based on the remaining parameters.
    #
    # Takes a hash of parameters from an incoming request to modify a model (via a controller,
    # service, or GraphQL mutation). The parameters will either be camelCase (if they are
    # received directly via controller params) or underscore_case (if they have come from
    # a GraphQL mutation which has converted them to underscore), or in the
    # headers when using the header based flow.
    #
    # Deletes the parameters which are related to spam and captcha processing, and returns
    # them in a SpamParams parameters object. See:
    # https://refactoring.com/catalog/introduceParameterObject.html
    def self.filter_spam_params!(params, request)
      # NOTE: The 'captcha_response' field can be expanded to multiple fields when we move to future
      # alternative captcha implementations such as FriendlyCaptcha. See
      # https://gitlab.com/gitlab-org/gitlab/-/issues/273480
      headers = request&.headers || {}
      api = params.delete(:api)
      captcha_response = read_parameter(:captcha_response, params, headers)
      spam_log_id      = read_parameter(:spam_log_id, params, headers)&.to_i

      SpamParams.new(api: api, captcha_response: captcha_response, spam_log_id: spam_log_id)
    end

    def self.read_parameter(name, params, headers)
      [
        params.delete(name),
        params.delete(name.to_s.camelize(:lower).to_sym),
        headers["X-GitLab-#{name.to_s.titlecase(keep_id_suffix: true).tr(' ', '-')}"]
      ].compact.first
    end

    attr_accessor :target, :request, :options
    attr_reader :spam_log

    def initialize(spammable:, request:, user:, action:)
      @target = spammable
      @request = request
      @user = user
      @action = action
      @options = {}
    end

    # rubocop:disable Metrics/AbcSize
    def execute(spam_params:)
      if request
        options[:ip_address] = request.env['action_dispatch.remote_ip'].to_s
        options[:user_agent] = request.env['HTTP_USER_AGENT']
        options[:referer] = request.env['HTTP_REFERER']
      else
        # TODO: This code is never used, because we do not perform a verification if there is not a
        #   request.  Why? Should it be deleted? Or should we check even if there is no request?
        options[:ip_address] = target.ip_address
        options[:user_agent] = target.user_agent
      end

      recaptcha_verified = Captcha::CaptchaVerificationService.new.execute(
        captcha_response: spam_params.captcha_response,
        request: request
      )

      if recaptcha_verified
        # If it's a request which is already verified through CAPTCHA,
        # update the spam log accordingly.
        SpamLog.verify_recaptcha!(user_id: user.id, id: spam_params.spam_log_id)
        ServiceResponse.success(message: "CAPTCHA successfully verified")
      else
        return ServiceResponse.success(message: 'Skipped spam check because user was allowlisted') if allowlisted?(user)
        return ServiceResponse.success(message: 'Skipped spam check because request was not present') unless request
        return ServiceResponse.success(message: 'Skipped spam check because it was not required') unless check_for_spam?

        perform_spam_service_check(spam_params.api)
        ServiceResponse.success(message: "Spam check performed. Check #{target.class.name} spammable model for any errors or CAPTCHA requirement")
      end
    end
    # rubocop:enable Metrics/AbcSize

    delegate :check_for_spam?, to: :target

    private

    attr_reader :user, :action

    ##
    # In order to be proceed to the spam check process, the target must be
    # a dirty instance, which means it should be already assigned with the new
    # attribute values.
    def ensure_target_is_dirty
      msg = "Target instance of #{target.class.name} must be dirty (must have changes to save)"
      raise(msg) unless target.has_changes_to_save?
    end

    def allowlisted?(user)
      user.try(:gitlab_employee?) || user.try(:gitlab_bot?) || user.try(:gitlab_service_user?)
    end

    ##
    # Performs the spam check using the spam verdict service, and modifies the target model
    # accordingly based on the result.
    def perform_spam_service_check(api)
      ensure_target_is_dirty

      # since we can check for spam, and recaptcha is not verified,
      # ask the SpamVerdictService what to do with the target.
      spam_verdict_service.execute.tap do |result|
        case result
        when CONDITIONAL_ALLOW
          # at the moment, this means "ask for reCAPTCHA"
          create_spam_log(api)

          break if target.allow_possible_spam?

          target.needs_recaptcha!
        when DISALLOW
          # TODO: remove `unless target.allow_possible_spam?` once this flag has been passed to `SpamVerdictService`
          # https://gitlab.com/gitlab-org/gitlab/-/issues/214739
          target.spam! unless target.allow_possible_spam?
          create_spam_log(api)
        when BLOCK_USER
          # TODO: improve BLOCK_USER handling, non-existent until now
          # https://gitlab.com/gitlab-org/gitlab/-/issues/329666
          target.spam! unless target.allow_possible_spam?
          create_spam_log(api)
        when ALLOW
          target.clear_spam_flags!
        when NOOP
          # spamcheck is not explicitly rendering a verdict & therefore can't make a decision
          target.clear_spam_flags!
        end
      end
    end

    def create_spam_log(api)
      @spam_log = SpamLog.create!(
        {
          user_id: target.author_id,
          title: target.spam_title,
          description: target.spam_description,
          source_ip: options[:ip_address],
          user_agent: options[:user_agent],
          noteable_type: noteable_type,
          via_api: api
        }
      )

      target.spam_log = spam_log
    end

    def spam_verdict_service
      context = {
        action: action,
        target_type: noteable_type
      }

      SpamVerdictService.new(target: target,
                             user: user,
                             request: request,
                             options: options,
                             context: context)
    end

    def noteable_type
      @notable_type ||= target.class.to_s
    end
  end
end
