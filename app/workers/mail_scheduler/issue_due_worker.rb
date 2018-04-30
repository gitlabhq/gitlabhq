module MailScheduler
  class IssueDueWorker
    include ApplicationWorker
    include MailSchedulerQueue

    def perform(project_id)
      Issue.opened.due_tomorrow.in_projects(project_id).preload(:project).find_each do |issue|
        notification_service.issue_due(issue)
      end
    end
  end
end
