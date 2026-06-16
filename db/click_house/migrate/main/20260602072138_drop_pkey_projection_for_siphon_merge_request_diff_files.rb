# frozen_string_literal: true

class DropPkeyProjectionForSiphonMergeRequestDiffFiles < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_merge_request_diff_files DROP PROJECTION IF EXISTS pg_pkey_ordered
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_merge_request_diff_files
        ADD PROJECTION IF NOT EXISTS pg_pkey_ordered
        (
          SELECT *
          ORDER BY
            merge_request_diff_id,
            relative_order
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_merge_request_diff_files MATERIALIZE PROJECTION pg_pkey_ordered
    SQL
  end
end
