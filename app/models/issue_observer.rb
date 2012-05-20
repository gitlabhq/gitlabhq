class IssueObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_create(issue)
    Notify.new_issue_email(issue.id) if issue.assignee != current_user
  end

  def after_change(issue)
    send_reassigned_email(issue) if issue.is_being_reassigned?
    Note.create_status_change_note(issue, current_user, 'closed') if issue.is_being_closed?
  end

  def send_reassigned_email(issue)
    recipient_ids = [issue.assignee_id, issue.assignee_id_was].keep_if {|id| id != current_user.id }

    recipient_ids.each do |recipient_id|
      Notify.reassigned_issue_email(recipient_id, issue.id, issue.assignee_id_was)
    end
  end
end
