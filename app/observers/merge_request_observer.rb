class MergeRequestObserver < BaseObserver
  cattr_accessor :current_user

  def after_create(merge_request)
    notification.new_merge_request(merge_request, current_user)
  end

  def after_close(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_reopen(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_update(merge_request)
    notification.reassigned_merge_request(merge_request) if merge_request.is_being_reassigned?
  end
end
