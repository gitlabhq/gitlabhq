# frozen_string_literal: true

class CreateSiphonPCiBuildsMetadata < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_builds_metadata
      (
        project_id Int64,
        timeout Nullable(Int64),
        timeout_source Int64 DEFAULT 1,
        interruptible Nullable(Bool) CODEC(ZSTD(1)),
        config_options Nullable(String),
        config_variables Nullable(String),
        has_exposed_artifacts Nullable(Bool) CODEC(ZSTD(1)),
        environment_auto_stop_in Nullable(String),
        expanded_environment_name Nullable(String),
        build_id Int64,
        id Int64 CODEC(DoubleDelta, ZSTD),
        partition_id Int64 CODEC(DoubleDelta, ZSTD),
        debug_trace_enabled Bool DEFAULT false CODEC(ZSTD(1)),
        exit_code Nullable(Int16),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
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
      DROP TABLE IF EXISTS siphon_p_ci_builds_metadata
    SQL
  end
end
