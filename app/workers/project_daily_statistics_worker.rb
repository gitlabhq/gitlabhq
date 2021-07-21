# frozen_string_literal: true

# Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/214585
class ProjectDailyStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management

  def perform(project_id)
    project = Project.find_by_id(project_id)

    return unless project&.repository&.exists?

    Projects::FetchStatisticsIncrementService.new(project).execute
  end
end
