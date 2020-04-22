# frozen_string_literal: true

module Spam
  class SpamActionService
    include SpamConstants

    attr_accessor :target, :request, :options
    attr_reader :spam_log

    def initialize(spammable:, request:)
      @target = spammable
      @request = request
      @options = {}

      if @request
        @options[:ip_address] = @request.env['action_dispatch.remote_ip'].to_s
        @options[:user_agent] = @request.env['HTTP_USER_AGENT']
        @options[:referrer] = @request.env['HTTP_REFERRER']
      else
        @options[:ip_address] = @target.ip_address
        @options[:user_agent] = @target.user_agent
      end
    end

    def execute(api: false, recaptcha_verified:, spam_log_id:, user_id:)
      if recaptcha_verified
        # If it's a request which is already verified through reCAPTCHA,
        # update the spam log accordingly.
        SpamLog.verify_recaptcha!(user_id: user_id, id: spam_log_id)
      else
        return unless request
        return unless check_for_spam?

        perform_spam_service_check(api)
      end
    end

    delegate :check_for_spam?, to: :target

    private

    def perform_spam_service_check(api)
      # since we can check for spam, and recaptcha is not verified,
      # ask the SpamVerdictService what to do with the target.
      spam_verdict_service.execute.tap do |result|
        case result
        when REQUIRE_RECAPTCHA
          create_spam_log(api)

          break if target.allow_possible_spam?

          target.needs_recaptcha!
        when DISALLOW
          # TODO: remove `unless target.allow_possible_spam?` once this flag has been passed to `SpamVerdictService`
          # https://gitlab.com/gitlab-org/gitlab/-/issues/214739
          target.spam! unless target.allow_possible_spam?
          create_spam_log(api)
        when ALLOW
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
          noteable_type: target.class.to_s,
          via_api: api
        }
      )

      target.spam_log = spam_log
    end

    def spam_verdict_service
      SpamVerdictService.new(target: target,
                             request: @request,
                             options: options)
    end
  end
end
