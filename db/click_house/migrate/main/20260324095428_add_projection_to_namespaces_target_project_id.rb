# frozen_string_literal: true

class AddProjectionToNamespacesTargetProjectId < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_projects
      MODIFY SETTING deduplicate_merge_projection_mode = 'rebuild'
    SQL

    execute <<~SQL
      ALTER TABLE siphon_projects
        ADD PROJECTION IF NOT EXISTS by_project_namespace_id
        (
          SELECT *
          ORDER BY project_namespace_id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_projects MATERIALIZE PROJECTION by_project_namespace_id
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_projects DROP PROJECTION IF EXISTS by_project_namespace_id
      SETTINGS mutations_sync = 0
    SQL
  end
end
