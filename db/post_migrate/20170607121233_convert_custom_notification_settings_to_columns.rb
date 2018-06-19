class ConvertCustomNotificationSettingsToColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class NotificationSetting < ApplicationRecord
    self.table_name = 'notification_settings'

    store :events, coder: JSON
  end

  EMAIL_EVENTS = [
    :new_note,
    :new_issue,
    :reopen_issue,
    :close_issue,
    :reassign_issue,
    :new_merge_request,
    :reopen_merge_request,
    :close_merge_request,
    :reassign_merge_request,
    :merge_merge_request,
    :failed_pipeline,
    :success_pipeline
  ]

  # We only need to migrate (up or down) rows where at least one of these
  # settings is set.
  def up
    NotificationSetting.where("events LIKE '%true%'").find_each do |notification_setting|
      EMAIL_EVENTS.each do |event|
        notification_setting[event] = notification_setting.events[event]
      end

      notification_setting[:events] = nil
      notification_setting.save!
    end
  end

  def down
    NotificationSetting.where(EMAIL_EVENTS.join(' OR ')).find_each do |notification_setting|
      events = {}

      EMAIL_EVENTS.each do |event|
        events[event] = !!notification_setting.public_send(event)
        notification_setting[event] = nil
      end

      notification_setting[:events] = events
      notification_setting.save!
    end
  end
end
