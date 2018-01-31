class RemoveDuplicatesInTrendingProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    connection.execute <<-SQL
      DELETE FROM trending_projects WHERE id IN (
        SELECT id FROM (
          SELECT
            id,
            ROW_NUMBER() OVER (PARTITION BY project_id) AS row_number
          FROM trending_projects
        ) t WHERE t.row_number > 1
      )
    SQL
  end

  def down
    # Do not restore duplicates here (no-op)
  end
end
