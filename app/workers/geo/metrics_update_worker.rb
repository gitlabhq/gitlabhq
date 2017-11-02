module Geo
  class MetricsUpdateWorker
    include Sidekiq::Worker
    include ExclusiveLeaseGuard
    include CronjobQueue

    LEASE_TIMEOUT = 5.minutes

    def perform
      return unless Gitlab::Metrics.prometheus_metrics_enabled?

      try_obtain_lease { Geo::MetricsUpdateService.new.execute }
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
