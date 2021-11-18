# frozen_string_literal: true

# Worker for updating project statistics.
class UpdateProjectStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management

  # project_id - The ID of the project for which to flush the cache.
  # statistics - An Array containing columns from ProjectStatistics to
  #              refresh, if empty all columns will be refreshed
  def perform(project_id, statistics = [])
    project = Project.find_by_id(project_id)

    Projects::UpdateStatisticsService.new(project, nil, statistics: statistics).execute
  end
end
