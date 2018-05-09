class EnsureProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab::Database.postgresql?

    execute <<-SQL
      INSERT INTO project_mirror_data (
        project_id,
        retry_count,
        last_update_started_at,
        last_update_scheduled_at,
        next_execution_timestamp
      )
      SELECT id AS project_id,
        0 AS retry_count,
        CAST(NULL AS TIMESTAMP) AS last_update_started_at,
        CAST(NULL AS TIMESTAMP) AS last_update_scheduled_at,
        NOW() AS next_execution_timestamp
      FROM projects
      WHERE mirror IS TRUE
      AND NOT EXISTS (
        SELECT true
        FROM project_mirror_data
        WHERE project_mirror_data.project_id = projects.id
      );
    SQL
  end

  def down
  end
end
