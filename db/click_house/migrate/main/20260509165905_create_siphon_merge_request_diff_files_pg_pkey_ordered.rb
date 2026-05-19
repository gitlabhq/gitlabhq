# frozen_string_literal: true

class CreateSiphonMergeRequestDiffFilesPgPkeyOrdered < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_request_diff_files_pg_pkey_ordered
      (
        merge_request_diff_id Int64 CODEC(DoubleDelta, ZSTD(1)),
        relative_order Int64 CODEC(DoubleDelta, ZSTD(1)),
        traversal_path String DEFAULT '0/' CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
        _siphon_deleted Bool DEFAULT false CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_diff_id, relative_order, traversal_path)
      ORDER BY (merge_request_diff_id, relative_order, traversal_path)
      SETTINGS index_granularity = 1024
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_request_diff_files_pg_pkey_ordered
    SQL
  end
end
