class ExportCsvWorker
  include ApplicationWorker

  def perform(current_user_id, project_id, params)
    @current_user = User.find(current_user_id)
    @project = Project.find(project_id)

    params.symbolize_keys!
    params[:project_id] = project_id
    params.delete(:sort)

    issues = IssuesFinder.new(@current_user, params).execute

    Issues::ExportCsvService.new(issues).email(@current_user, @project)
  end
end
