module MailSchedulerQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :mail_scheduler
  end

  def notification_service
    @notification_service ||= NotificationService.new
  end
end
