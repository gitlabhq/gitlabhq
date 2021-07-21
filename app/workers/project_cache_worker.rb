# frozen_string_literal: true

# Worker for updating any project specific caches.
class ProjectCacheWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  LEASE_TIMEOUT = 15.minutes.to_i

  feature_category :source_code_management
  urgency :high
  loggable_arguments 1, 2, 3
  idempotent!

  # project_id - The ID of the project for which to flush the cache.
  # files - An Array containing extra types of files to refresh such as
  #         `:readme` to flush the README and `:changelog` to flush the
  #         CHANGELOG.
  # statistics - An Array containing columns from ProjectStatistics to
  #              refresh, if empty all columns will be refreshed
  # refresh_statistics - A boolean that determines whether project statistics should
  #                     be updated.
  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, files = [], statistics = [], refresh_statistics = true)
    project = Project.find_by(id: project_id)

    return unless project

    update_statistics(project, statistics) if refresh_statistics

    return unless project.repository.exists?

    project.repository.refresh_method_caches(files.map(&:to_sym))

    project.cleanup
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # NOTE: triggering both an immediate update and one in 15 minutes if we
  # successfully obtain the lease. That way, we only need to wait for the
  # statistics to become accurate if they were already updated once in the
  # last 15 minutes.
  def update_statistics(project, statistics = [])
    return if Gitlab::Database.read_only?
    return unless try_obtain_lease_for(project.id, statistics)

    Projects::UpdateStatisticsService.new(project, nil, statistics: statistics).execute

    UpdateProjectStatisticsWorker.perform_in(LEASE_TIMEOUT, project.id, statistics)
  end

  private

  def try_obtain_lease_for(project_id, statistics)
    Gitlab::ExclusiveLease
      .new(project_cache_worker_key(project_id, statistics), timeout: LEASE_TIMEOUT)
      .try_obtain
  end

  def project_cache_worker_key(project_id, statistics)
    ["project_cache_worker", project_id, *statistics.sort].join(":")
  end
end

ProjectCacheWorker.prepend_mod_with('ProjectCacheWorker')
