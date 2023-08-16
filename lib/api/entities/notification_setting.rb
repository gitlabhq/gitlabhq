# frozen_string_literal: true

module API
  module Entities
    class NotificationSetting < Grape::Entity
      expose :level
      expose :events, if: ->(notification_setting, _) { notification_setting.custom? } do |setting|
        setting.email_events.index_with do |event_name|
          setting[event_name]
        end
      end
    end
  end
end
