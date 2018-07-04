# frozen_string_literal: true

# Worker for updating any project specific caches.
class ProjectCacheWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard
  prepend EE::Workers::ProjectCacheWorker

  LEASE_TIMEOUT = 15.minutes.to_i

  # project_id - The ID of the project for which to flush the cache.
  # files - An Array containing extra types of files to refresh such as
  #         `:readme` to flush the README and `:changelog` to flush the
  #         CHANGELOG.
  # statistics - An Array containing columns from ProjectStatistics to
  #              refresh, if empty all columns will be refreshed
  def perform(project_id, files = [], statistics = [])
    @project = Project.find_by(id: project_id)
    return unless @project&.repository&.exists?

    update_statistics(statistics)

    @project.repository.refresh_method_caches(files.map(&:to_sym))

    @project.cleanup
  end

  private

  def update_statistics(statistics = [])
    try_obtain_lease do
      Rails.logger.info("Updating statistics for project #{@project.id}")
      @project.statistics.refresh!(only: statistics.to_a.map(&:to_sym))
    end
  end

  def lease_timeout
    LEASE_TIMEOUT
  end

  def lease_key
    "project_cache_worker:#{@project.id}:update_statistics"
  end
end
