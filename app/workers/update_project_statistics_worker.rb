# frozen_string_literal: true

# Worker for updating project statistics.
class UpdateProjectStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management

  # lease_key     - The exclusive lease key to take
  # project_id    - The ID of the project for which to flush the cache.
  # statistics    - An Array containing columns from ProjectStatistics to
  #                 refresh, if empty all columns will be refreshed
  def perform(lease_key, project_id, statistics = [])
    return unless Gitlab::ExclusiveLease
      .new(lease_key, timeout: ProjectCacheWorker::LEASE_TIMEOUT)
      .try_obtain

    project = Project.find_by_id(project_id)

    Projects::UpdateStatisticsService.new(project, nil, statistics: statistics).execute
  end
end
