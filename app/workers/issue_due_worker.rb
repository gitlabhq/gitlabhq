class IssueDueWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Issue.where(due_date: Date.today).find_each do |issue|
      NotificationService.new.issue_due_email(issue)
    end
  end
end
