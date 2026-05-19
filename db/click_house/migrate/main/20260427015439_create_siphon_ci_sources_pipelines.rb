# frozen_string_literal: true

class CreateSiphonCiSourcesPipelines < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ci_sources_pipelines
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        project_id Int64,
        source_project_id Nullable(Int64),
        source_job_id Nullable(Int64),
        partition_id Int64,
        source_partition_id Int64,
        pipeline_id Nullable(Int64),
        source_pipeline_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_ci_sources_pipelines
    SQL
  end
end
