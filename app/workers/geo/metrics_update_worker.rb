module Geo
  class MetricsUpdateWorker
    include Sidekiq::Worker
    include ExclusiveLeaseGuard
    include CronjobQueue

    LEASE_TIMEOUT = 5.minutes

    def perform
      try_obtain_lease { Geo::MetricsUpdateService.new.execute }
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def log_error(message, extra_args = {})
      args = { class: self.class.name, message: message }.merge(extra_args)
      Gitlab::Geo::Logger.error(args)
    end
  end
end
