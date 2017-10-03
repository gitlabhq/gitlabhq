class LfsProjectCleanupWorker
  include Sidekiq::Worker

  def perform(project_id)
    project = Project.find_by(id: project_id)

    return unless project

    LfsCleanupService.new(project).remove_unreferenced
  end
end
