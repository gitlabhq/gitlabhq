class ExportCsvWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(current_user_id, project_id, params)
    @current_user = User.find(current_user_id)
    @project = Project.find(project_id)

    params[:project_id] = project_id

    issues = IssuesFinder.new(@current_user, params.symbolize_keys).execute

    Issues::ExportCsvService.new(issues).email(@current_user, @project)
  end
end
