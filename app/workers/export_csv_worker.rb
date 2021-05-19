# frozen_string_literal: true

class ExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :issue_tracking
  worker_resource_boundary :cpu
  loggable_arguments 2

  def perform(current_user_id, project_id, params)
    @current_user = User.find(current_user_id)
    @project = Project.find(project_id)

    params.symbolize_keys!
    params[:project_id] = project_id
    params.delete(:sort)

    IssuableExportCsvWorker.perform_async(:issue, @current_user.id, @project.id, params)
  end
end
