class NewIssueWorker
  include ApplicationWorker
  include NewIssuable

  def perform(issue_id, user_id)
    return unless objects_found?(issue_id, user_id)

    EventCreateService.new.open_issue(issuable, user)
    NotificationService.new.new_issue(issuable, user)
    issuable.create_cross_references!(user)
  end

  def issuable_class
    Issue
  end
end
