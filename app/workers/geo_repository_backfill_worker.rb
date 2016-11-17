class GeoRepositoryBackfillWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include GeoQueue

  def perform(geo_node_id, project_id)
    project = Project.find(project_id)
    geo_node = GeoNode.find(geo_node_id)

    return unless project && geo_node

    Geo::RepositoryBackfillService.new(project, geo_node).execute
  end
end
