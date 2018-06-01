module Geo
  class PruneEventLogWorker
    include ApplicationWorker
    include CronjobQueue
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    LEASE_TIMEOUT = 60.minutes
    TRUNCATE_DELAY = 10.minutes

    def perform
      return if Gitlab::Database.read_only?

      try_obtain_lease do
        if Gitlab::Geo.secondary_nodes.empty?
          log_info('No secondary nodes configured, scheduling truncation of the Geo Event Log')

          ::Geo::TruncateEventLogWorker.perform_in(TRUNCATE_DELAY)

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
        Geo::EventLog.where('id <= ?', cursor_last_event_ids.min)
                     .each_batch { |batch| batch.delete_all }
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
