# frozen_string_literal: true

class CreateSiphonMergeRequestDiffs < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_request_diffs
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        state LowCardinality(Nullable(String)),
        merge_request_id Int64,
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        base_commit_sha Nullable(String),
        real_size Nullable(String),
        head_commit_sha Nullable(String),
        start_commit_sha Nullable(String),
        commits_count Nullable(Int64),
        external_diff Nullable(String),
        external_diff_store Nullable(Int64) DEFAULT 1,
        stored_externally Bool DEFAULT false CODEC(ZSTD(1)),
        files_count Nullable(Int16),
        sorted Bool DEFAULT false CODEC(ZSTD(1)),
        diff_type Int8 DEFAULT 1,
        patch_id_sha Nullable(String),
        project_id Int64,
        traversal_path String DEFAULT multiIf(
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
      PRIMARY KEY (traversal_path, merge_request_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_request_diffs
    SQL
  end
end
