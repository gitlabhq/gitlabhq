# frozen_string_literal: true

module API
  module Entities
    class GlobalNotificationSetting < Entities::NotificationSetting
      expose :notification_email do |notification_setting, options|
        notification_setting.user.notification_email_or_default
      end
    end
  end
end
