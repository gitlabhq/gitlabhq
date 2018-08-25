class MigrateUsersNotificationLevel < ActiveRecord::Migration
  DOWNTIME = false

  # Migrates only users who changed their default notification level :participating
  # creating a new record on notification settings table

  def up
    execute(%Q{
      INSERT INTO notification_settings
      (user_id, level, created_at, updated_at)
      (SELECT id, notification_level, created_at, updated_at FROM users WHERE notification_level != 1)
    })
  end

  # Migrates from notification settings back to user notification_level
  # If no value is found the default level of 1 will be used
  def down
    execute(%Q{
      UPDATE users u SET
      notification_level = COALESCE((SELECT level FROM notification_settings WHERE user_id = u.id AND source_type IS NULL), 1)
    })
  end
end
