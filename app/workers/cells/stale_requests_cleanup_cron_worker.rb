# frozen_string_literal: true

module Cells
  class StaleRequestsCleanupCronWorker
    include ApplicationWorker

    # This worker does not schedule other workers that require context.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- This worker cleans up stale Redis entries and does not need context

    data_consistency :sticky
    feature_category :cell
    urgency :low

    idempotent!

    # This worker only interacts with Redis, not the database,
    # but we still defer on database health signals as a good citizen
    defer_on_database_health_signal :gitlab_main, [], 5.minutes

    def perform
      result = Gitlab::TopologyServiceClient::ConcurrencyLimitService.cleanup_stale_requests
      log_extra_metadata_on_done(:removed_count, result[:removed_count])
    end
  end
end
