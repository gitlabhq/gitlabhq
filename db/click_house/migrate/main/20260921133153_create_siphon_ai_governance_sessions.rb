# frozen_string_literal: true

class CreateSiphonAiGovernanceSessions < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ai_governance_sessions
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        namespace_id Int64,
        project_id Nullable(Int64),
        user_id Int64,
        workflow_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        session_started_at DateTime64(6, 'UTC') CODEC(DoubleDelta, ZSTD(1)),
        session_finished_at Nullable(DateTime64(6, 'UTC')),
        source Int16 DEFAULT 0,
        status Int16 DEFAULT 0,
        external_xid Nullable(String),
        agent_type Nullable(String),
        flow_type Nullable(String),
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, session_started_at, id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_ai_governance_sessions
    SQL
  end
end
