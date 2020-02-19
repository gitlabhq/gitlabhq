# frozen_string_literal: true

class ProjectDailyStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management

  def perform(project_id)
    project = Project.find_by_id(project_id)

    return unless project&.repository&.exists?

    Projects::FetchStatisticsIncrementService.new(project).execute
  end
end
