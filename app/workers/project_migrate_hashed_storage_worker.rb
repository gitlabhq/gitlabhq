class ProjectMigrateHashedStorageWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil? || project.pending_delete?

    ::Projects::HashedStorageMigrationService.new(project, logger).execute
  end
end
