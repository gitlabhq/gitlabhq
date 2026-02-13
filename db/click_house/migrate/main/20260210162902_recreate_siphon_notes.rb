# frozen_string_literal: true

class RecreateSiphonNotes < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_notes
      (
        note String CODEC(ZSTD(3)),
        noteable_type LowCardinality(String),
        author_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        project_id Nullable(Int64),
        line_code Nullable(String),
        commit_id Nullable(String),
        noteable_id Int64,
        system Bool DEFAULT false CODEC(ZSTD(1)),
        st_diff Nullable(String),
        updated_by_id Nullable(Int64),
        type LowCardinality(String),
        position Nullable(String),
        original_position Nullable(String),
        resolved_at Nullable(DateTime64(6, 'UTC')),
        resolved_by_id Nullable(Int64),
        discussion_id String CODEC(ZSTD(1)),
        change_position Nullable(String),
        resolved_by_push Nullable(Bool) CODEC(ZSTD(1)),
        review_id Nullable(Int64),
        confidential Bool CODEC(ZSTD(1)),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        internal Bool DEFAULT false CODEC(ZSTD(1)),
        id Int64 CODEC(DoubleDelta, ZSTD),
        namespace_id Nullable(Int64),
        imported_from Int8 DEFAULT 0,
        organization_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(
          coalesce(namespace_id, 0) != 0,
          dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'),
          coalesce(project_id, 0) != 0,
          dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
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
      PRIMARY KEY (traversal_path, noteable_type, noteable_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_notes
    SQL
  end
end
