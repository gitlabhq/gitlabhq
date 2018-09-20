# frozen_string_literal: true

module Geo
  class PruneEventLogWorker
    include ApplicationWorker
    include CronjobQueue
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::Geo::LogHelpers

    LEASE_TIMEOUT = 5.minutes

    def perform
      return if Gitlab::Database.read_only?
      return unless Gitlab::Database.healthy?

      unless ::GeoNode.any?
        Geo::PruneEventLogService.new(:all).execute
        return
      end

      unless prune?
        log_info('Some nodes are not healthy, prune geo event log skipped', unhealthy_node_count: unhealthy_nodes.count)
        return
      end

      Geo::PruneEventLogService.new(min_cursor_last_event_id).execute
    end

    def prune?
      unhealthy_nodes.empty?
    end

    def min_cursor_last_event_id
      ::GeoNode.secondary_nodes.min_cursor_last_event_id
    end

    def unhealthy_nodes
      ::GeoNode.secondary_nodes.unhealthy_nodes
    end
  end
end
