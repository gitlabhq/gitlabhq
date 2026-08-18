# frozen_string_literal: true

class AddPipelineIdProjectionToSiphonPCiStages < ClickHouse::Migration
  # Columns are listed explicitly: `SELECT *` breaks projection rebuilds when a
  # column is added to the base table later (see !225458).
  def up
    execute <<~SQL
      ALTER TABLE siphon_p_ci_stages
        ADD PROJECTION IF NOT EXISTS by_traversal_path_pipeline_id
        (
          SELECT
            id,
            partition_id,
            traversal_path,
            pipeline_id,
            name,
            status,
            _siphon_replicated_at,
            _siphon_deleted
          ORDER BY
            traversal_path,
            pipeline_id,
            id,
            partition_id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_p_ci_stages MATERIALIZE PROJECTION by_traversal_path_pipeline_id
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_p_ci_stages DROP PROJECTION IF EXISTS by_traversal_path_pipeline_id
      SETTINGS mutations_sync = 0
    SQL
  end
end
