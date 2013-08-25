class BaseObserver < ActiveRecord::Observer
  def notification
    NotificationService.new
  end

  def log_info message
    Gitlab::AppLogger.info message
  end

  def current_user
    Thread.current[:current_user]
  end

  def current_commit
    Thread.current[:current_commit]
  end
end
