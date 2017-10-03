class LfsProjectCleanupWorker
  include Sidekiq::Worker

  def perform(project_id)
    project = Project.find(project_id)

    LfsCleanupService.new(project).remove_unreferenced
  end
end
