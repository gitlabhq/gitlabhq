class IssueDueWorker
  include ApplicationWorker

  def perform(issue_id)
    issue = Issue.find_by_id(issue_id)
    # How do we want to deal with noops?
    if issue.due_date == Date.today
      # execute
    end
  end
end
