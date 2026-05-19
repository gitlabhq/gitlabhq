# frozen_string_literal: true

class RecreateSiphonNamespaceDetails < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_namespace_details
      (
        namespace_id Int64 CODEC(DoubleDelta, ZSTD),
        created_at Nullable(DateTime64(6, 'UTC')) CODEC(Delta, ZSTD(1)),
        updated_at Nullable(DateTime64(6, 'UTC')) CODEC(Delta, ZSTD(1)),
        cached_markdown_version Nullable(Int64),
        description Nullable(String) CODEC(ZSTD(3)),
        description_html Nullable(String) CODEC(ZSTD(3)),
        creator_id Nullable(Int64),
        state_metadata String DEFAULT '{}' CODEC(ZSTD(3)),
        deletion_scheduled_at Nullable(DateTime64(6, 'UTC')),
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY namespace_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, namespace_id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_namespace_details
    SQL
  end
end
