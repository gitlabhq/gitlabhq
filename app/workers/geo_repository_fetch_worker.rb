# TODO: Remove me once Geo is fixed
class GeoRepositoryFetchWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  sidekiq_options queue: 'geo_repository_update'

  def perform(project_id, clone_url)
    project = Project.find(project_id)

    project.create_repository unless project.repository_exists?
    project.repository.after_create if project.empty_repo?
    project.repository.fetch_geo_mirror(clone_url)
  end
end
