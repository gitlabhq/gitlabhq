# frozen_string_literal: true

module Metrics
  class GlobalMetricsUpdateWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :metrics

    include ExclusiveLeaseGuard
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    LEASE_TIMEOUT = 2.minutes

    def perform
      try_obtain_lease { ::Metrics::GlobalMetricsUpdateService.new.execute }
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
