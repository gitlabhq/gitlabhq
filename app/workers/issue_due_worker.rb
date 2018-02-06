class IssueDueWorker
  include ApplicationWorker

  def perform(issue_id)
    issue = Issue.find_by_id(issue_id)
    if issue.due_date == Date.today
      NotificationService.new.issue_due_email(issue)
    end
  end
end
