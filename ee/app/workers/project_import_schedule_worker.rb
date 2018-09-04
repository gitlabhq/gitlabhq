class ProjectImportScheduleWorker
  include ApplicationWorker
  prepend WaitableWorker

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id)
    project = Project.find_by(id: project_id)
    project&.import_schedule
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
