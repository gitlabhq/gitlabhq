# frozen_string_literal: true

class CreateSiphonEventsWithTraversalPath < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_events
      (
        project_id Nullable(Int64),
        author_id Int64,
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        action Int16,
        target_type LowCardinality(String) DEFAULT '',
        group_id Nullable(Int64),
        fingerprint Nullable(String),
        id Int64 CODEC(DoubleDelta, ZSTD),
        target_id Nullable(Int64),
        imported_from Int16 DEFAULT 0,
        personal_namespace_id Nullable(Int64),
        path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'), coalesce(personal_namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', personal_namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (path, id)
      PARTITION BY toYear(created_at)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_events
    SQL
  end
end
