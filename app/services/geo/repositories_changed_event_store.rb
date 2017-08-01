module Geo
  class RepositoriesChangedEventStore < EventStore
    self.event_type = :repositories_changed_event

    attr_reader :geo_node

    def initialize(geo_node)
      @geo_node = geo_node
    end

    private

    def build_event
      Geo::RepositoriesChangedEvent.new(geo_node: geo_node)
    end

    def log_error(message, error)
      Gitlab::Geo::Logger.error(
        class: self.class.name,
        message: message,
        error: error,
        geo_node_id: geo_node.id,
        geo_node_url: geo_node.url)
    end
  end
end
