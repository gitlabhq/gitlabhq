class UsersGroupObserver < BaseObserver
  def after_create(membership)
    notification.new_group_member(membership)
  end

  def after_update(membership)
    notification.update_group_member(membership) if membership.group_access_changed?
  end
end
