# frozen_string_literal: true

class AddStartedAtProjectionToSiphonPCiBuilds < ClickHouse::Migration
  # Columns are listed explicitly instead of `SELECT *`. With `SELECT *`,
  # adding a new column to siphon_p_ci_builds later would leave the existing
  # projection parts missing that column, breaking subsequent mutations under
  # `deduplicate_merge_projection_mode = 'rebuild'`. See !225458 for the
  # incident this avoids.
  def up
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds
        ADD PROJECTION IF NOT EXISTS by_traversal_path_started_at
        (
          SELECT
            id,
            partition_id,
            traversal_path,
            started_at,
            finished_at,
            name,
            stage_id,
            status,
            type,
            commit_id,
            _siphon_replicated_at,
            _siphon_deleted
          ORDER BY
            traversal_path,
            started_at,
            id,
            partition_id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds MATERIALIZE PROJECTION by_traversal_path_started_at
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds DROP PROJECTION IF EXISTS by_traversal_path_started_at
      SETTINGS mutations_sync = 0
    SQL
  end
end
