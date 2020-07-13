# frozen_string_literal: true

module Spam
  class SpamVerdictService
    include AkismetMethods
    include SpamConstants

    def initialize(user:, target:, request:, options:, context: {})
      @target = target
      @request = request
      @user = user
      @options = options
      @verdict_params = assemble_verdict_params(context)
    end

    def execute
      external_spam_check_result = external_verdict
      akismet_result = akismet_verdict

      # filter out anything we don't recognise, including nils.
      valid_results = [external_spam_check_result, akismet_result].compact.select { |r| SUPPORTED_VERDICTS.key?(r) }
      # Treat nils - such as service unavailable - as ALLOW
      return ALLOW unless valid_results.any?

      # Favour the most restrictive result.
      valid_results.min_by { |v| SUPPORTED_VERDICTS[v][:priority] }
    end

    private

    attr_reader :user, :target, :request, :options, :verdict_params

    def akismet_verdict
      if akismet.spam?
        Gitlab::Recaptcha.enabled? ? CONDITIONAL_ALLOW : DISALLOW
      else
        ALLOW
      end
    end

    def external_verdict
      return unless Gitlab::CurrentSettings.spam_check_endpoint_enabled
      return if endpoint_url.blank?

      begin
        result = Gitlab::HTTP.post(endpoint_url, body: verdict_params.to_json, headers: { 'Content-Type' => 'application/json' })
        return unless result

        json_result = Gitlab::Json.parse(result).with_indifferent_access
        # @TODO metrics/logging
        # Expecting:
        # error: (string or nil)
        # verdict: (string or nil)
        # @TODO log if json_result[:error]

        json_result[:verdict]
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        # @TODO: log error via try_post https://gitlab.com/gitlab-org/gitlab/-/issues/219223
        Gitlab::ErrorTracking.log_exception(e)
        nil
      rescue
        # @TODO log
        ALLOW
      end
    end

    def assemble_verdict_params(context)
      return {} unless endpoint_url.present?

      project = target.try(:project)

      context.merge({
        target: {
          title: target.spam_title,
          description: target.spam_description,
          type: target.class.to_s
        },
        user: {
          created_at: user.created_at,
          email: user.email,
          username: user.username
        },
        user_in_project: user.authorized_project?(project)
      })
    end

    def endpoint_url
      @endpoint_url ||= Gitlab::CurrentSettings.current_application_settings.spam_check_endpoint_url
    end
  end
end
