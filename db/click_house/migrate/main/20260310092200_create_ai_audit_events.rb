# frozen_string_literal: true

class CreateAiAuditEvents < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS ai_audit_events
      (
        id UUID CODEC(ZSTD(1)),
        event_name LowCardinality(String) DEFAULT '',
        created_at DateTime64(6, 'UTC') DEFAULT now64() CODEC(Delta, ZSTD(1)),
        author_id UInt64 DEFAULT 0 CODEC(ZSTD(1)),
        project_id Nullable(UInt64) CODEC(ZSTD(1)),
        group_id Nullable(UInt64) CODEC(ZSTD(1)),
        ip_address String DEFAULT '' CODEC(ZSTD(1)),
        workflow_id UInt64 DEFAULT 0 CODEC(DoubleDelta, ZSTD),
        details String DEFAULT '{}' CODEC(ZSTD(3)),
        traversal_path String DEFAULT multiIf(
          coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
          coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)),
        PROJECTION by_workflow_id (
          SELECT *
          ORDER BY workflow_id, created_at, id
        )
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYYYYMM(created_at)
      ORDER BY (traversal_path, workflow_id, created_at, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS ai_audit_events
    SQL
  end
end
