class IssueDueSchedulerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Issue.opened.due_tomorrow.group(:project_id).pluck(:project_id).each do |project_id|
      MailScheduler::IssueDueWorker.perform_async(project_id)
    end
  end
end
