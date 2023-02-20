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
      spamcheck_result = nil
      spamcheck_attribs = {}
      spamcheck_error = false

      external_spam_check_round_trip_time = Benchmark.realtime do
        spamcheck_result, spamcheck_attribs, spamcheck_error = spamcheck_verdict
      end

      label = spamcheck_error ? 'ERROR' : spamcheck_result.to_s.upcase

      histogram.observe({ result: label }, external_spam_check_round_trip_time)

      # assign result to a var for logging it before reassigning to nil when monitorMode is true
      original_spamcheck_result = spamcheck_result

      spamcheck_result = nil if spamcheck_attribs&.fetch("monitorMode", "false") == "true"

      akismet_result = akismet_verdict

      # filter out anything we don't recognise, including nils.
      valid_results = [spamcheck_result, akismet_result].compact.select { |r| SUPPORTED_VERDICTS.key?(r) }

      # Treat nils - such as service unavailable - as ALLOW
      return ALLOW unless valid_results.any?

      # Favour the most restrictive result.
      verdict = valid_results.min_by { |v| SUPPORTED_VERDICTS[v][:priority] }

      # The target can override the verdict via the `allow_possible_spam` application setting
      verdict = OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM if override_via_allow_possible_spam?(verdict: verdict)

      logger.info(class: self.class.name,
                  akismet_verdict: akismet_verdict,
                  spam_check_verdict: original_spamcheck_result,
                  extra_attributes: spamcheck_attribs,
                  spam_check_rtt: external_spam_check_round_trip_time.real,
                  final_verdict: verdict,
                  username: user.username,
                  user_id: user.id,
                  target_type: target.class.to_s,
                  project_id: target.project_id
                 )

      verdict
    end

    private

    attr_reader :user, :target, :options, :context, :extra_features

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
        result, attribs, _error = spamcheck_client.spam?(spammable: target, user: user, context: context,
                                                         extra_features: extra_features)
        # @TODO log if error is not nil https://gitlab.com/gitlab-org/gitlab/-/issues/329545

        return [nil, attribs] unless result

        [result, attribs]

      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, error: ERROR_TYPE)

        # Default to ALLOW if any errors occur
        [ALLOW, attribs, true]
      end
    end

    def override_via_allow_possible_spam?(verdict:)
      # If the verdict is already going to allow (because current verdict's priority value is greater
      # than the override verdict's priority value), then we don't need to override it.
      return false if SUPPORTED_VERDICTS[verdict][:priority] > SUPPORTED_VERDICTS[OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM][:priority]

      target.allow_possible_spam?
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
