class IssueObserver < BaseObserver
  def after_create(issue)
    notification.new_issue(issue, current_user)
    issue.create_cross_references!(issue.project, current_user)
    execute_hooks(issue)
  end

  def after_close(issue, transition)
    notification.close_issue(issue, current_user)
    create_note(issue)
    execute_hooks(issue)
  end

  def after_reopen(issue, transition)
    create_note(issue)
    execute_hooks(issue)
  end

  def after_update(issue)
    if issue.is_being_reassigned?
      notification.reassigned_issue(issue, current_user)
      create_assignee_note(issue)
    end

    issue.notice_added_references(issue.project, current_user)
    execute_hooks(issue)
  end

  protected

  # Create issue note with service comment like 'Status changed to closed'
  def create_note(issue)
    Note.create_status_change_note(issue, issue.project, current_user, issue.state, current_commit)
  end

  def create_assignee_note(issue)
    Note.create_assignee_change_note(issue, issue.project, current_user, issue.assignee)
  end

  def execute_hooks(issue)
    issue.project.execute_hooks(issue.to_hook_data, :issue_hooks)
  end
end
