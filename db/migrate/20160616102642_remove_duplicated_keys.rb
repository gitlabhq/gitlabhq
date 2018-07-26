class RemoveDuplicatedKeys < ActiveRecord::Migration
  def up
    select_all("SELECT fingerprint FROM #{quote_table_name(:keys)} GROUP BY fingerprint HAVING COUNT(*) > 1").each do |row|
      fingerprint = connection.quote(row['fingerprint'])
      execute(%Q{
        DELETE FROM #{quote_table_name(:keys)}
        WHERE fingerprint = #{fingerprint}
        AND id != (
          SELECT id FROM (
            SELECT max(id) AS id
            FROM #{quote_table_name(:keys)}
            WHERE fingerprint = #{fingerprint}
          ) max_ids
        )
      })
    end
  end
end
