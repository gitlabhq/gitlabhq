class MigrateUsersNotificationLevel < ActiveRecord::Migration
  # Migrates only users which changes theier default notification level :participating
  # creating a new record on notification settins table

  def up
    changed_users = exec_query(%Q{
      SELECT id, notification_level
      FROM users
      WHERE notification_level != 1
    })

    changed_users.each do |row|
      uid = row['id']
      u_notification_level = row['notification_level']

      execute(%Q{
        INSERT INTO notification_settings
          (user_id, level, created_at, updated_at)
        VALUES
          (#{uid}, #{u_notification_level}, now(), now())
      })
    end
  end
end
