# frozen_string_literal: true

class CreateSiphonResourceStateEvents < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_resource_state_events
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        user_id Nullable(Int64),
        issue_id Nullable(Int64),
        merge_request_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        state Int16,
        epic_id Nullable(Int64),
        source_commit Nullable(String),
        close_after_error_tracking_resolve Bool DEFAULT false CODEC(ZSTD(1)),
        close_auto_resolve_prometheus_alert Bool DEFAULT false CODEC(ZSTD(1)),
        source_merge_request_id Nullable(Int64),
        imported_from Int16 DEFAULT 0,
        namespace_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_resource_state_events
    SQL
  end
end
