# frozen_string_literal: true

module JiraConnect
  class RetryRequestWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :delayed
    queue_namespace :jira_connect
    feature_category :team_planning
    urgency :low

    worker_has_external_dependencies!

    INITIAL_ATTEMPTS = 3
    # Delays indexed by retry number (0 = first retry, 1 = second, etc).
    # The index is clamped to a valid position, so any retry beyond the
    # listed entries uses the last delay.
    RETRY_DELAYS = [30.seconds, 5.minutes, 30.minutes].freeze

    def perform(proxy_url, jwt, attempts = INITIAL_ATTEMPTS, total_attempts = attempts)
      r = Integrations::Clients::HTTP.post(proxy_url, headers: { 'Authorization' => "JWT #{jwt}" })

      return if r.code < 400

      if retryable_response_code?(r.code) && attempts > 0
        schedule_retry(proxy_url, jwt, attempts, total_attempts)
      else
        log_dropped_request(proxy_url, "HTTP #{r.code}")
      end
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      if attempts > 0
        schedule_retry(proxy_url, jwt, attempts, total_attempts)
      else
        log_dropped_request(proxy_url, e.class.name)
      end
    end

    private

    def retryable_response_code?(code)
      code == 429 || code >= 500
    end

    def schedule_retry(proxy_url, jwt, remaining_attempts, total_attempts)
      retry_index = total_attempts - remaining_attempts
      # An out-of-range retry_index (e.g. if a caller passes inconsistent
      # `attempts` / `total_attempts`) falls back to the longest delay rather
      # than relying on Ruby's negative-index semantics.
      delay = retry_index.between?(0, RETRY_DELAYS.length - 1) ? RETRY_DELAYS[retry_index] : RETRY_DELAYS.last
      self.class.perform_in(delay, proxy_url, jwt, remaining_attempts - 1, total_attempts)
    end

    def log_dropped_request(proxy_url, reason)
      Gitlab::AppLogger.error(
        message: 'JiraConnect::RetryRequestWorker dropped request',
        proxy_url: proxy_url,
        reason: reason
      )
    end
  end
end
