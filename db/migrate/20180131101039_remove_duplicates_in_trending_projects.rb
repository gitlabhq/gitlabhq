class RemoveDuplicatesInTrendingProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      execute <<~SQL
        DELETE FROM trending_projects WHERE id IN (
          SELECT id FROM (
            SELECT
              id,
              ROW_NUMBER() OVER (PARTITION BY project_id) AS row_number
            FROM trending_projects
          ) t WHERE t.row_number > 1
        )
      SQL
    else
      # No window functions in Mysql 5.x
      # We can't modify a table we are selecting from on MySQL
      fail 'TODO'
    end
  end

  def down
    # Do not restore duplicates here (no-op)
  end
end
