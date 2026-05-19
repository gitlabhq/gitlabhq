# frozen_string_literal: true

class CreateSiphonMergeRequestDiffFilesPgPkeyOrderedMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS siphon_merge_request_diff_files_pg_pkey_ordered_mv
      TO siphon_merge_request_diff_files_pg_pkey_ordered
      AS
      SELECT
        merge_request_diff_id,
        relative_order,
        traversal_path,
        _siphon_replicated_at,
        _siphon_deleted
      FROM siphon_merge_request_diff_files
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS siphon_merge_request_diff_files_pg_pkey_ordered_mv'
  end
end
