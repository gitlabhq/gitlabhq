class UserObserver < ActiveRecord::Observer
  def after_create(user)
    log_info("User \"#{user.name}\" (#{user.email}) was created")
    unless user.extern_uid?
      Notify.new_user_email(user.id, user.password).deliver
    end
  end

  def after_destroy user
    log_info("User \"#{user.name}\" (#{user.email})  was removed")
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
