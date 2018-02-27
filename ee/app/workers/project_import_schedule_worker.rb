class ProjectImportScheduleWorker
  include ApplicationWorker
  prepend WaitableWorker

  def perform(project_id)
    project = Project.find_by(id: project_id)
    project&.import_schedule
  end
end
