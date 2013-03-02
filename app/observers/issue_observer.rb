class IssueObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_create(issue)
    if issue.assignee && issue.assignee != current_user
      Notify.delay.new_issue_email(issue.id)
    end
  end

  def after_close(issue, transition)
    send_reassigned_email(issue) if issue.is_being_reassigned?

    create_note(issue)
  end

  def after_reopen(issue, transition)
    send_reassigned_email(issue) if issue.is_being_reassigned?

    create_note(issue)
  end

  def after_update(issue)
    send_reassigned_email(issue) if issue.is_being_reassigned?
  end

  protected

  def create_note(issue)
    Note.create_status_change_note(issue, current_user, issue.state)
    [issue.author, issue.assignee].compact.uniq.each do |recipient|
      Notify.delay.issue_status_changed_email(recipient.id, issue.id, issue.state, current_user.id)
    end
  end

  def send_reassigned_email(issue)
    recipient_ids = [issue.assignee_id, issue.assignee_id_was].keep_if {|id| id && id != current_user.id }

    recipient_ids.each do |recipient_id|
      Notify.delay.reassigned_issue_email(recipient_id, issue.id, issue.assignee_id_was)
    end
  end
end
