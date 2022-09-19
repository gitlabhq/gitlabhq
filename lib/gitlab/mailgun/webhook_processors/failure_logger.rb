# frozen_string_literal: true

module Gitlab
  module Mailgun
    module WebhookProcessors
      class FailureLogger < Base
        def execute
          log_failure if permanent_failure_over_threshold? || temporary_failure_over_threshold?
        end

        def permanent_failure_over_threshold?
          payload['event'] == 'failed' && payload['severity'] == 'permanent' &&
            Gitlab::ApplicationRateLimiter.throttled?(:permanent_email_failure, scope: payload['recipient'])
        end

        def temporary_failure_over_threshold?
          payload['event'] == 'failed' && payload['severity'] == 'temporary' &&
            Gitlab::ApplicationRateLimiter.throttled?(:temporary_email_failure, scope: payload['recipient'])
        end

        private

        def log_failure
          Gitlab::ErrorTracking::Logger.error(
            event: 'email_delivery_failure',
            mailgun_event_id: payload['id'],
            recipient: payload['recipient'],
            failure_type: payload['severity'],
            failure_reason: payload['reason'],
            failure_code: payload.dig('delivery-status', 'code'),
            failure_message: payload.dig('delivery-status', 'message')
          )
        end
      end
    end
  end
end
