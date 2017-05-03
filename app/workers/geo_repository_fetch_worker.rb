class GeoRepositoryFetchWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include GeoQueue
  include Gitlab::ShellAdapter

  sidekiq_options queue: 'geo_repository_update'

  def perform(project_id, clone_url)
    project = Project.find(project_id)

    project.create_repository unless project.repository_exists?
    project.repository.after_create if project.empty_repo?
    project.repository.fetch_geo_mirror(clone_url)
    project.repository.expire_all_method_caches
    project.repository.expire_branch_cache
    project.repository.expire_content_cache
  rescue Gitlab::Shell::Error => e
    logger.error "Error fetching repository for project #{project.path_with_namespace}: #{e}"
  end
end
