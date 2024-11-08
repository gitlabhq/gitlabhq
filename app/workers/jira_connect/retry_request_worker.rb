# frozen_string_literal: true

module JiraConnect
  class RetryRequestWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :delayed
    queue_namespace :jira_connect
    feature_category :integrations
    urgency :low

    worker_has_external_dependencies!

    def perform(proxy_url, jwt, attempts = 3)
      r = Gitlab::HTTP.post(proxy_url, headers: { 'Authorization' => "JWT #{jwt}" })

      self.class.perform_in(1.hour, proxy_url, jwt, attempts - 1) if r.code >= 400 && attempts > 0
    rescue *Gitlab::HTTP::HTTP_ERRORS
      self.class.perform_in(1.hour, proxy_url, jwt, attempts - 1) if attempts > 0
    end
  end
end
