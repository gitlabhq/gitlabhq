# Worker for updating any project specific caches.
class ProjectCacheWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 15.minutes.to_i

  # project_id - The ID of the project for which to flush the cache.
  # files - An Array containing extra types of files to refresh such as
  #         `:readme` to flush the README and `:changelog` to flush the
  #         CHANGELOG.
  # statistics - An Array containing columns from ProjectStatistics to
  #              refresh, if empty all columns will be refreshed
  def perform(project_id, files = [], statistics = [])
    project = Project.find_by(id: project_id)

    return unless project && project.repository.exists?

    update_statistics(project, statistics.map(&:to_sym))

    project.repository.refresh_method_caches(files.map(&:to_sym))

    project.cleanup
  end

  def update_statistics(project, statistics = [])
    return unless try_obtain_lease_for(project.id, :update_statistics)

    Rails.logger.info("Updating statistics for project #{project.id}")

    project.statistics.refresh!(only: statistics)
  end

  private

  def try_obtain_lease_for(project_id, section)
    Gitlab::ExclusiveLease
      .new("project_cache_worker:#{project_id}:#{section}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
