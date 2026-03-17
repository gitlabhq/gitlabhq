# frozen_string_literal: true

class CreateSiphonPCiBuilds < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_builds
      (
        status LowCardinality(String) default '',
        finished_at Nullable(DateTime64(6, 'UTC')),
        created_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') default now() CODEC(Delta, ZSTD(1)),
        started_at Nullable(DateTime64(6, 'UTC')),
        coverage Nullable(Float64),
        name Nullable(String),
        options Nullable(String),
        allow_failure Bool DEFAULT false CODEC(ZSTD(1)),
        stage_idx Nullable(Int64),
        tag Nullable(Bool) CODEC(ZSTD(1)),
        ref Nullable(String),
        type LowCardinality(String) default '',
        target_url Nullable(String),
        description Nullable(String) CODEC(ZSTD(3)),
        erased_at Nullable(DateTime64(6, 'UTC')),
        artifacts_expire_at Nullable(DateTime64(6, 'UTC')),
        environment LowCardinality(String) default '',
        when LowCardinality(String) default '',
        yaml_variables Nullable(String),
        queued_at Nullable(DateTime64(6, 'UTC')),
        lock_version Int64 DEFAULT 0,
        coverage_regex Nullable(String),
        retried Nullable(Bool) CODEC(ZSTD(1)),
        protected Nullable(Bool) CODEC(ZSTD(1)),
        failure_reason Nullable(Int64),
        scheduled_at Nullable(DateTime64(6, 'UTC')),
        token_encrypted Nullable(String),
        resource_group_id Nullable(Int64),
        waiting_for_resource_at Nullable(DateTime64(6, 'UTC')),
        processed Nullable(Bool) CODEC(ZSTD(1)),
        scheduling_type Nullable(Int16),
        id Int64 CODEC(DoubleDelta, ZSTD),
        stage_id Nullable(Int64),
        partition_id Int64 CODEC(DoubleDelta, ZSTD),
        auto_canceled_by_partition_id Nullable(Int64),
        auto_canceled_by_id Nullable(Int64),
        commit_id Nullable(Int64),
        erased_by_id Nullable(Int64),
        project_id Int64,
        runner_id Nullable(Int64),
        upstream_pipeline_id Nullable(Int64),
        user_id Nullable(Int64),
        execution_config_id Nullable(Int64),
        upstream_pipeline_partition_id Nullable(Int64),
        scoped_user_id Nullable(Int64),
        timeout Nullable(Int64),
        timeout_source Nullable(Int16),
        exit_code Nullable(Int16),
        debug_trace_enabled Nullable(Bool) CODEC(ZSTD(1)),
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
      DROP TABLE IF EXISTS siphon_p_ci_builds
    SQL
  end
end
