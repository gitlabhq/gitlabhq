# == Notifiable concern
#
# Contains notification functionality
#
module Notifiable
  extend ActiveSupport::Concern

  included do
    validates :notification_level, inclusion: { in: Notification.project_notification_levels }, presence: true
  end

  def notification
    @notification ||= Notification.new(self)
  end
end
