# This migration will create one row of NotificationSetting for each Member row
# It can take long time on big instances.
#
# This migration can be done online but with following effects:
# - during migration some users will receive notifications based on their global settings (project/group settings will be ignored)
# - its possible to get duplicate records for notification settings since we don't create uniq index yet
#
class MigrateNewNotificationSetting < ActiveRecord::Migration
  def up
    timestamp = Time.now.strftime('%F %T')
    execute "INSERT INTO notification_settings ( user_id, source_id, source_type, level, created_at, updated_at ) SELECT user_id, source_id, source_type, notification_level, '#{timestamp}', '#{timestamp}' FROM members WHERE user_id IS NOT NULL"
  end

  def down
    execute "DELETE FROM notification_settings"
  end
end
