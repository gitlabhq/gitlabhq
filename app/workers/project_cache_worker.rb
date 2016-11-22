# Worker for updating any project specific caches.
class ProjectCacheWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue
  prepend EE::Workers::ProjectCacheWorker

  LEASE_TIMEOUT = 15.minutes.to_i

  # project_id - The ID of the project for which to flush the cache.
  # refresh - An Array containing extra types of data to refresh such as
  #           `:readme` to flush the README and `:changelog` to flush the
  #           CHANGELOG.
  def perform(project_id, refresh = [])
    project = Project.find_by(id: project_id)

    return unless project && project.repository.exists?

    update_repository_size(project)
    project.update_commit_count

    project.repository.refresh_method_caches(refresh.map(&:to_sym))
  end

  def update_repository_size(project)
    return unless try_obtain_lease_for(project.id, :update_repository_size)

    Rails.logger.info("Updating repository size for project #{project.id}")

    project.update_repository_size
  end

  private

  def try_obtain_lease_for(project_id, section)
    Gitlab::ExclusiveLease.
      new("project_cache_worker:#{project_id}:#{section}", timeout: LEASE_TIMEOUT).
      try_obtain
  end
end
