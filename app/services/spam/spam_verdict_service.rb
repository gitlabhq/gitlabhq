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
      @context = context
    end

    def execute
      spamcheck_result = nil

      external_spam_check_round_trip_time = Benchmark.realtime do
        spamcheck_result = spamcheck_verdict
      end

      akismet_result = akismet_verdict

      # filter out anything we don't recognise, including nils.
      valid_results = [spamcheck_result, akismet_result].compact.select { |r| SUPPORTED_VERDICTS.key?(r) }

      # Treat nils - such as service unavailable - as ALLOW
      return ALLOW unless valid_results.any?

      # Favour the most restrictive result.
      final_verdict = valid_results.min_by { |v| SUPPORTED_VERDICTS[v][:priority] }

      logger.info(class: self.class.name,
                  akismet_verdict: akismet_verdict,
                  spam_check_verdict: spamcheck_result,
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

    attr_reader :user, :target, :request, :options, :context

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
        result, _error = spamcheck_client.issue_spam?(spam_issue: target, user: user, context: context)
        return unless result

        # @TODO log if error is not nil https://gitlab.com/gitlab-org/gitlab/-/issues/329545

        # Duplicate logic with Akismet logic in #akismet_verdict
        if Gitlab::Recaptcha.enabled? && result != ALLOW
          CONDITIONAL_ALLOW
        else
          result
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e)
        # Default to ALLOW if any errors occur
        ALLOW
      end
    end

    def spamcheck_client
      @spamcheck_client ||= Gitlab::Spamcheck::Client.new
    end

    def logger
      @logger ||= Gitlab::AppJsonLogger.build
    end
  end
end
