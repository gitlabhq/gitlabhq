# Worker for updating any project specific caches.
#
# This worker runs at most once every 15 minutes per project. This is to ensure
# that multiple instances of jobs for this worker don't hammer the underlying
# storage engine as much.
class ProjectCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  LEASE_TIMEOUT = 15.minutes.to_i

  def perform(project_id)
    if try_obtain_lease_for(project_id)
      Rails.logger.
        info("Obtained ProjectCacheWorker lease for project #{project_id}")
    else
      Rails.logger.
        info("Could not obtain ProjectCacheWorker lease for project #{project_id}")

      return
    end

    update_caches(project_id)
  end

  def update_caches(project_id)
    project = Project.find(project_id)

    return unless project.repository.exists?

    project.update_repository_size
    project.update_commit_count

    if project.repository.root_ref
      project.repository.build_cache
    end
  end

  def try_obtain_lease_for(project_id)
    Gitlab::ExclusiveLease.
      new("project_cache_worker:#{project_id}", timeout: LEASE_TIMEOUT).
      try_obtain
  end
end
