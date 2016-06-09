class RemoveDuplicatedNotificationSettings < ActiveRecord::Migration
  def up
    duplicates = exec_query(%Q{
      SELECT user_id, source_type, source_id
      FROM notification_settings
      GROUP BY user_id, source_type, source_id
      HAVING COUNT(*) > 1
    })

    duplicates.each do |row|
      uid = row['user_id']
      stype = connection.quote(row['source_type'])
      sid = row['source_id']

      execute(%Q{
        DELETE FROM notification_settings
        WHERE user_id = #{uid}
        AND source_type = #{stype}
        AND source_id = #{sid}
        AND id != (
          SELECT id FROM (
            SELECT min(id) AS id
            FROM notification_settings
            WHERE user_id = #{uid}
            AND source_type = #{stype}
            AND source_id = #{sid}
          ) min_ids
        )
      })
    end
  end
end
