# frozen_string_literal: true

module Spam
  class SpamVerdictService
    include AkismetMethods
    include SpamConstants

    def initialize(user:, target:, options:, context: {})
      @target = target
      @user = user
      @options = options
      @context = context
    end

    def execute
      spamcheck_result = nil
      spamcheck_attribs = {}
      spamcheck_error = false

      external_spam_check_round_trip_time = Benchmark.realtime do
        spamcheck_result, spamcheck_attribs, spamcheck_error = spamcheck_verdict
      end

      label = spamcheck_error ? 'ERROR' : spamcheck_result.to_s.upcase

      histogram.observe( { result: label }, external_spam_check_round_trip_time )

      # assign result to a var for logging it before reassigning to nil when monitorMode is true
      original_spamcheck_result = spamcheck_result

      spamcheck_result = nil if spamcheck_attribs&.fetch("monitorMode", "false") == "true"

      akismet_result = akismet_verdict

      # filter out anything we don't recognise, including nils.
      valid_results = [spamcheck_result, akismet_result].compact.select { |r| SUPPORTED_VERDICTS.key?(r) }

      # Treat nils - such as service unavailable - as ALLOW
      return ALLOW unless valid_results.any?

      # Favour the most restrictive result.
      final_verdict = valid_results.min_by { |v| SUPPORTED_VERDICTS[v][:priority] }

      logger.info(class: self.class.name,
                  akismet_verdict: akismet_verdict,
                  spam_check_verdict: original_spamcheck_result,
                  extra_attributes: spamcheck_attribs,
                  spam_check_rtt: external_spam_check_round_trip_time.real,
                  final_verdict: final_verdict,
                  username: user.username,
                  user_id: user.id,
                  target_type: target.class.to_s,
                  project_id: target.project_id
                 )

      final_verdict
    end

    private

    attr_reader :user, :target, :options, :context

    def akismet_verdict
      if akismet.spam?
        Gitlab::Recaptcha.enabled? ? CONDITIONAL_ALLOW : DISALLOW
      else
        ALLOW
      end
    end

    def spamcheck_verdict
      return unless Gitlab::CurrentSettings.spam_check_endpoint_enabled

      begin
        result, attribs, _error = spamcheck_client.issue_spam?(spam_issue: target, user: user, context: context)
        return [nil, attribs] unless result

        # @TODO log if error is not nil https://gitlab.com/gitlab-org/gitlab/-/issues/329545

        return [result, attribs] if result == NOOP || attribs["monitorMode"] == "true"

        # Duplicate logic with Akismet logic in #akismet_verdict
        if Gitlab::Recaptcha.enabled? && result != ALLOW
          [CONDITIONAL_ALLOW, attribs]
        else
          [result, attribs]
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e)

        # Default to ALLOW if any errors occur
        [ALLOW, attribs, true]
      end
    end

    def spamcheck_client
      @spamcheck_client ||= Gitlab::Spamcheck::Client.new
    end

    def logger
      @logger ||= Gitlab::AppJsonLogger.build
    end

    def histogram
      @histogram ||= Gitlab::Metrics.histogram(:gitlab_spamcheck_request_duration_seconds, 'Request duration to the anti-spam service')
    end
  end
end
