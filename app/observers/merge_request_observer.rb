class MergeRequestObserver < ActiveRecord::Observer
  cattr_accessor :current_user

  def after_create(merge_request)
    notification.new_merge_request(merge_request, current_user)
  end

  def after_close(merge_request, transition)
    send_reassigned_email(merge_request) if merge_request.is_being_reassigned?

    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_reopen(merge_request, transition)
    send_reassigned_email(merge_request) if merge_request.is_being_reassigned?

    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_update(merge_request)
    send_reassigned_email(merge_request) if merge_request.is_being_reassigned?
  end

  protected

  def send_reassigned_email(merge_request)
    recipients_ids = merge_request.assignee_id_was, merge_request.assignee_id
    recipients_ids.delete current_user.id

    recipients_ids.each do |recipient_id|
      Notify.delay.reassigned_merge_request_email(recipient_id, merge_request.id, merge_request.assignee_id_was)
    end
  end
end
