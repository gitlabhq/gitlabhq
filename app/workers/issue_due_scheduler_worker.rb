class IssueDueSchedulerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    project_ids = Issue.opened.due_tomorrow.group(:project_id).pluck(:project_id).map { |id| [id] }

    MailScheduler::IssueDueWorker.bulk_perform_async(project_ids)
  end
end
