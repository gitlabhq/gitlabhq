module Geo
  class PruneEventLogWorker
    include Sidekiq::Worker
    include CronjobQueue
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    LEASE_TIMEOUT = 60.minutes

    def lease_timeout
      LEASE_TIMEOUT
    end

    def perform
      return unless Gitlab::Geo.primary?

      try_obtain_lease do
        if Gitlab::Geo.secondary_nodes.empty?
          Geo::EventLog.delete_all
          return
        end

        cursor_last_event_ids = Gitlab::Geo.secondary_nodes.map do |node|
          Geo::NodeStatusService.new.call(node).cursor_last_event_id
        end

        # Abort when any of the nodes could not be contacted
        return if cursor_last_event_ids.include?(nil)

        Geo::EventLog.delete_all(['id < ?', cursor_last_event_ids.min])
      end
    end
  end
end
