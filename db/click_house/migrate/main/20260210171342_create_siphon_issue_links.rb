# frozen_string_literal: true

class CreateSiphonIssueLinks < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_issue_links
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        source_id Int64 CODEC(DoubleDelta, ZSTD),
        target_id Int64,
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        link_type Int8 DEFAULT 0,
        namespace_id Int64,
        traversal_path String DEFAULT multiIf(
          coalesce(namespace_id, 0) != 0,
          dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, source_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_issue_links
    SQL
  end
end
