class IssueObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_create(issue)
    if issue.assignee && issue.assignee != current_user
      Notify.new_issue_email(issue.id).deliver
    end
  end

  def after_update(issue)
    send_reassigned_email(issue) if issue.is_being_reassigned?

    status = nil
    status = 'closed' if issue.is_being_closed?
    status = 'reopened' if issue.is_being_reopened?
    if status
      Note.create_status_change_note(issue, current_user, status)
      [issue.author, issue.assignee].compact.each do |recipient|
        Notify.issue_status_changed_email(recipient.id, issue.id, status, current_user.id).deliver
      end
    end
  end

  protected

  def send_reassigned_email(issue)
    recipient_ids = [issue.assignee_id, issue.assignee_id_was].keep_if {|id| id && id != current_user.id }

    recipient_ids.each do |recipient_id|
      Notify.reassigned_issue_email(recipient_id, issue.id, issue.assignee_id_was).deliver
    end
  end
end
