class ProjectExportWorker
  include ApplicationWorker
  include ExceptionBacktrace

  sidekiq_options retry: 3

  def perform(current_user_id, project_id, params = {})
    params = params.with_indifferent_access
    current_user = User.find(current_user_id)
    project = Project.find(project_id)

    ::Projects::ImportExport::ExportService.new(project, current_user, params).execute
  end
end
