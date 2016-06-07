class RemoveDuplicatedNotificationSettings < ActiveRecord::Migration
  def up
    execute <<-SQL
      DELETE FROM notification_settings WHERE id NOT IN ( SELECT min_id from (SELECT MIN(id) as min_id FROM notification_settings GROUP BY user_id, source_type, source_id) as dups )
    SQL
  end
end
