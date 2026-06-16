# frozen_string_literal: true

class DropSiphonPCiBuildsMetadataTable < ClickHouse::Migration
  def up
    execute 'DROP VIEW IF EXISTS siphon_p_ci_builds_metadata_pg_pkey_ordered_mv'
    execute 'DROP TABLE IF EXISTS siphon_p_ci_builds_metadata_pg_pkey_ordered'
    execute 'DROP TABLE IF EXISTS siphon_p_ci_builds_metadata'
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_builds_metadata
      (
          `project_id` Int64,
          `timeout` Nullable(Int64),
          `timeout_source` Int64 DEFAULT 1,
          `interruptible` Nullable(Bool) CODEC(ZSTD(1)),
          `config_options` Nullable(String),
          `config_variables` Nullable(String),
          `has_exposed_artifacts` Nullable(Bool) CODEC(ZSTD(1)),
          `environment_auto_stop_in` Nullable(String),
          `expanded_environment_name` Nullable(String),
          `build_id` Int64,
          `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
          `partition_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
          `debug_trace_enabled` Bool DEFAULT false CODEC(ZSTD(1)),
          `exit_code` Nullable(Int16),
          `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
          `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id, partition_id)
      ORDER BY (traversal_path, id, partition_id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_builds_metadata_pg_pkey_ordered
      (
          `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
          `partition_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
          `traversal_path` String DEFAULT '0/' CODEC(ZSTD(3)),
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
          `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (id, partition_id, traversal_path)
      ORDER BY (id, partition_id, traversal_path)
      SETTINGS index_granularity = 1024;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS siphon_p_ci_builds_metadata_pg_pkey_ordered_mv TO siphon_p_ci_builds_metadata_pg_pkey_ordered
      (
          `id` Int64,
          `partition_id` Int64,
          `traversal_path` String,
          `_siphon_replicated_at` DateTime64(6, 'UTC'),
          `_siphon_deleted` Bool
      )
      AS SELECT
          id,
          partition_id,
          traversal_path,
          _siphon_replicated_at,
          _siphon_deleted
      FROM siphon_p_ci_builds_metadata;
    SQL
  end
end
