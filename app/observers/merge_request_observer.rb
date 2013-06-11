class MergeRequestObserver < BaseObserver
  def after_create(merge_request)
    notification.new_merge_request(merge_request, current_user)
  end

  def after_close(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)

    notification.close_mr(merge_request, current_user)
  end

  def after_merge(merge_request, transition)
    notification.merge_mr(merge_request)
  end

  def after_reopen(merge_request, transition)
    Note.create_status_change_note(merge_request, current_user, merge_request.state)
  end

  def after_update(merge_request)
    notification.reassigned_merge_request(merge_request, current_user) if merge_request.is_being_reassigned?
  end
end
