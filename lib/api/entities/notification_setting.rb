# frozen_string_literal: true

module API
  module Entities
    class NotificationSetting < Grape::Entity
      expose :level
      expose :events, if: ->(notification_setting, _) { notification_setting.custom? } do
        ::NotificationSetting.email_events.each do |event|
          expose event
        end
      end
    end
  end
end
