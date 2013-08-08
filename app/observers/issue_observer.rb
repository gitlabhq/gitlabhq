class IssueObserver < BaseObserver
  def after_create(issue)
    notification.new_issue(issue, current_user)
  end

  def after_close(issue, transition)
    notification.close_issue(issue, current_user)

    create_note(issue)
  end

  def after_reopen(issue, transition)
    create_note(issue)
  end

  def after_update(issue)
    if issue.is_being_reassigned?
      notification.reassigned_issue(issue, current_user)
    end
  end

  protected

  # Create issue note with service comment like 'Status changed to closed'
  def create_note(issue)
    Note.create_status_change_note(issue, issue.project, current_user, issue.state)
  end
end
