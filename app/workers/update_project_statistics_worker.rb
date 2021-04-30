# frozen_string_literal: true

# Worker for updating project statistics.
class UpdateProjectStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management

  # project_id - The ID of the project for which to flush the cache.
  # statistics - An Array containing columns from ProjectStatistics to
  #              refresh, if empty all columns will be refreshed
  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, statistics = [])
    project = Project.find_by(id: project_id)

    Projects::UpdateStatisticsService.new(project, nil, statistics: statistics).execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
