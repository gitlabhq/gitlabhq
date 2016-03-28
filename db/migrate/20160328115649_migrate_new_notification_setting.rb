# This migration will create one row of NotificationSetting for each Member row
# It can take long time on big instances. Its unclear yet if this migration can be done online.
# This comment should be updated by @dzaporozhets before 8.7 release. If not - please ask him to do so.
class MigrateNewNotificationSetting < ActiveRecord::Migration
  def up
    timestamp = Time.now
    execute "INSERT INTO notification_settings ( user_id, source_id, source_type, level, created_at, updated_at ) SELECT user_id, source_id, source_type, notification_level, '#{timestamp}', '#{timestamp}' FROM members WHERE user_id IS NOT NULL"
  end

  def down
    NotificationSetting.delete_all
  end
end
