module Geo
  class RepositoriesCleanUpWorker
    include Sidekiq::Worker
    include GeoQueue

    def perform(geo_node_id)
      geo_node = GeoNode.find(geo_node_id)
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::Geo::Logger.error(
        class: self.class.name,
        message: 'Could not find Geo node, skipping repositories clean up',
        geo_node_id: geo_node_id,
        error: e
      )
    end
  end
end
