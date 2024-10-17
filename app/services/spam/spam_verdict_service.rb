# frozen_string_literal: true

module Spam
  class SpamVerdictService
    include AkismetMethods
    include SpamConstants

    def initialize(user:, target:, options:, context: {}, extra_features: {})
      @target = target
      @user = user
      @options = options
      @context = context
      @extra_features = extra_features
    end

    def execute
      spamcheck_verdict = nil

      external_spam_check_round_trip_time = Benchmark.realtime do
        spamcheck_verdict = get_spamcheck_verdict
      end

      histogram.observe({ result: spamcheck_verdict.upcase }, external_spam_check_round_trip_time) if spamcheck_verdict

      akismet_verdict = get_akismet_verdict

      # filter out anything we don't recognise, including nils.
      valid_verdicts = [spamcheck_verdict, akismet_verdict].compact.select { |r| SUPPORTED_VERDICTS.key?(r) }

      # Treat nils - such as service unavailable - as ALLOW
      return ALLOW unless valid_verdicts.any?

      # Favour the most restrictive verdict
      final_verdict = valid_verdicts.min_by { |v| SUPPORTED_VERDICTS[v][:priority] }

      # The target can override the verdict via the `allow_possible_spam` application setting
      final_verdict = OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM if override_via_allow_possible_spam?(verdict: final_verdict)

      logger.info(
        class: self.class.name,
        akismet_verdict: akismet_verdict,
        spam_check_verdict: spamcheck_verdict,
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

    attr_reader :user, :target, :options, :context, :extra_features

    def get_akismet_verdict
      if akismet.spam?
        Gitlab::Recaptcha.enabled? ? CONDITIONAL_ALLOW : DISALLOW
      else
        ALLOW
      end
    end

    def get_spamcheck_verdict
      return unless Gitlab::CurrentSettings.spam_check_endpoint_enabled

      begin
        result = spamcheck_client.spam?(spammable: target, user: user, context: context, extra_features: extra_features)

        if result.evaluated?
          correlation_id = Labkit::Correlation::CorrelationId.current_id || ''
          AntiAbuse::TrustScoreWorker.perform_async(user.id, :spamcheck, result.score, correlation_id)
        end

        result.verdict

      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, error: ERROR_TYPE)
        nil
      end
    end

    def override_via_allow_possible_spam?(verdict:)
      # If the verdict is already going to allow (because current verdict's priority value is greater
      # than the override verdict's priority value), then we don't need to override it.
      return false if SUPPORTED_VERDICTS[verdict][:priority] > SUPPORTED_VERDICTS[OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM][:priority]

      allow_possible_spam?
    end

    def allow_possible_spam?
      target.allow_possible_spam?(user) || user.trusted?
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

Spam::SpamVerdictService.prepend_mod
