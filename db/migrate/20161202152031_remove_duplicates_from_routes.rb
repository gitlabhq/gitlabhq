# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDuplicatesFromRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    select_all("SELECT path FROM #{quote_table_name(:routes)} GROUP BY path HAVING COUNT(*) > 1").each do |row|
      path = connection.quote(row['path'])
      execute(%Q{
        DELETE FROM #{quote_table_name(:routes)}
        WHERE path = #{path}
        AND id != (
          SELECT id FROM (
            SELECT max(id) AS id
            FROM #{quote_table_name(:routes)}
            WHERE path = #{path}
          ) max_ids
        )
      })
    end
  end

  def down
  end
end
