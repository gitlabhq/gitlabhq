class GeoRepositoryFetchWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include GeoQueue
  include Gitlab::ShellAdapter

  sidekiq_options queue: 'geo_repository_update'

  def perform(project_id, clone_url)
    project = Project.find(project_id)
    Geo::RepositoryUpdateService.new(project, clone_url, logger).execute
  end
end
