module Users
  module NewUserNotifier
    def notify_new_user(user, reset_token)
      log_info("User \"#{user.name}\" (#{user.email}) was created")
      notification_service.new_user(user, reset_token) if reset_token
      system_hook_service.execute_hooks_for(user, :create)
    end
  end
end
