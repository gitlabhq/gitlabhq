class UserObserver < BaseObserver
  def after_create(user)
    log_info("User \"#{user.name}\" (#{user.email}) was created")
    notification.new_user(user)
    system_hook_service.execute_hooks_for(user, :create)
  end

  def after_destroy user
    log_info("User \"#{user.name}\" (#{user.email})  was removed")
    system_hook_service.execute_hooks_for(user, :destroy)
  end

  def after_save user
    # Ensure user has namespace
    user.create_namespace!(path: user.username, name: user.username) unless user.namespace

    if user.username_changed?
      user.namespace.update_attributes(path: user.username, name: user.username)
    end
  end
end
