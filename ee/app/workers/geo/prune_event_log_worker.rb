module Geo
  class PruneEventLogWorker
    include ApplicationWorker
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
          log_info('No secondary nodes, delete all Geo Event Log entries')
          Geo::EventLog.delete_all
          break
        end

        cursor_last_event_ids = Gitlab::Geo.secondary_nodes.map do |node|
          node.status&.cursor_last_event_id
        end

        if cursor_last_event_ids.include?(nil)
          log_info('Could not get status of all nodes, not deleting any entries from Geo Event Log', unhealthy_node_count: cursor_last_event_ids.count(nil))
          break
        end

        log_info('Delete Geo Event Log entries up to id', geo_event_log_id: cursor_last_event_ids.min)
        Geo::EventLog.where('id < ?', cursor_last_event_ids.min).delete_all
      end
    end
  end
end
