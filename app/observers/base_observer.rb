class BaseObserver < ActiveRecord::Observer
  def notification
    NotificationService.new
  end

  def event_service
    EventCreateService.new
  end

  def log_info message
    Gitlab::AppLogger.info message
  end
end
