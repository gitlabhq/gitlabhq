class GeoSingleRepositoryBackfillWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include GeoQueue

  def perform(project_id, lease)
    Geo::RepositoryBackfillService.new(project_id, lease).execute
  end
end
