class RemoveDuplicatesFromProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<-SQL
      WITH good_rows AS (
        SELECT project_id, MAX(id) as max_id
        FROM project_registry
        GROUP BY project_id
        HAVING COUNT(*) > 1
      )
      DELETE FROM project_registry duplicated_rows
      USING good_rows
      WHERE good_rows.project_id = duplicated_rows.project_id
        AND good_rows.max_id <> duplicated_rows.id;
    SQL
  end

  def down
  end
end
