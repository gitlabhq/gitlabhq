class ProjectExportWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  sidekiq_options retry: 3

  def perform(current_user_id, project_id)
    current_user = User.find(current_user_id)
    project = Project.find(project_id)

    ::Projects::ImportExport::ExportService.new(project, current_user).execute
  end
end
