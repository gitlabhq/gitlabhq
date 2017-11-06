class LfsProjectCleanupWorker
  include Sidekiq::Worker

  LEASE_TIMEOUT = 7.days.to_i

  def perform(project_id)
    project = Project.find_by(id: project_id)

    return unless project

    LfsCleanupService.new(project).remove_unreferenced
  end

  def self.perform_async_with_lease(project_id)
    return unless not_recently_scheduled(project_id)

    perform_async(project_id)
  end

  def self.not_recently_scheduled(project_id)
    Gitlab::ExclusiveLease.new("lfs_project_cleanup_worker:#{project_id}", timeout: LEASE_TIMEOUT).try_obtain
  end
end
