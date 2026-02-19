# frozen_string_literal: true

class CreateSiphonPCiStages < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_stages
      (
        project_id Int64,
        created_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        name Nullable(String),
        status Nullable(Int64),
        lock_version Int64 DEFAULT 0,
        position Nullable(Int64),
        id Int64 CODEC(DoubleDelta, ZSTD),
        partition_id Int64 CODEC(DoubleDelta, ZSTD),
        pipeline_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(
          coalesce(project_id, 0) != 0,
          dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id, partition_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id, partition_id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_p_ci_stages
    SQL
  end
end
