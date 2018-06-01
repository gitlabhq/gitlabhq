module Geo
  class TruncateEventLogWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    def perform
      if Gitlab::Geo.secondary_nodes.any?
        log_info('Some secondary nodes configured, Geo Event Log should not be truncated', geo_node_count: Gitlab::Geo.secondary_nodes.count)
      else
        log_info('Still no secondary nodes configured, truncating the Geo Event Log')
        ActiveRecord::Base.connection.truncate(Geo::EventLog.table_name)
      end
    end
  end
end
