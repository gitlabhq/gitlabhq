# frozen_string_literal: true

class CreateSiphonPCiPipelines < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_p_ci_pipelines
      (
        ref Nullable(String),
        sha Nullable(String),
        before_sha Nullable(String),
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        tag Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
        yaml_errors Nullable(String),
        committed_at Nullable(DateTime64(6, 'UTC')),
        project_id Int64,
        status LowCardinality(String) default '',
        started_at Nullable(DateTime64(6, 'UTC')),
        finished_at Nullable(DateTime64(6, 'UTC')),
        duration Nullable(Int64),
        user_id Nullable(Int64),
        lock_version Int64 DEFAULT 0,
        pipeline_schedule_id Nullable(Int64),
        source Nullable(Int64),
        config_source Nullable(Int64),
        protected Nullable(Bool) CODEC(ZSTD(1)),
        failure_reason Nullable(Int64),
        iid Nullable(Int64),
        merge_request_id Nullable(Int64),
        source_sha Nullable(String),
        target_sha Nullable(String),
        external_pull_request_id Nullable(Int64),
        ci_ref_id Nullable(Int64),
        locked Int16 DEFAULT 1,
        partition_id Int64 CODEC(DoubleDelta, ZSTD),
        id Int64 CODEC(DoubleDelta, ZSTD),
        auto_canceled_by_id Nullable(Int64),
        auto_canceled_by_partition_id Nullable(Int64),
        trigger_id Nullable(Int64),
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
      DROP TABLE IF EXISTS siphon_p_ci_pipelines
    SQL
  end
end
