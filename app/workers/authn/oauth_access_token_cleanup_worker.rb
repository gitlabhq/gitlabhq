# frozen_string_literal: true

module Authn
  class OauthAccessTokenCleanupWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

    idempotent!
    deduplicate :until_executed
    data_consistency :sticky
    feature_category :system_access
    concurrency_limit -> { 1 }
    defer_on_database_health_signal :gitlab_main, [:oauth_access_tokens], 5.minutes

    MAX_RUNTIME = 3.minutes
    REQUEUE_DELAY = 3.minutes
    ITERATION_DELAY = 0.1
    BATCH_SIZE = 10_000
    SUB_BATCH_SIZE = 1_000

    def perform
      return unless Feature.enabled?(:cleanup_access_tokens, :instance)

      runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

      OauthAccessToken.each_batch(of: BATCH_SIZE) do |batch|
        batch.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
          # rubocop: disable CodeReuse/ActiveRecord -- We don't want to expose this as a scope since there is no index on these columns, and it should not be used outside of this worker.
          sub_batch.where("created_at + \(expires_in * INTERVAL'1 SECOND'\) < NOW()").delete_all
          # rubocop: enable CodeReuse/ActiveRecord

          sleep ITERATION_DELAY
        end

        self.class.perform_in(REQUEUE_DELAY) && break if runtime_limiter.over_time?
      end
    end
  end
end
