# frozen_string_literal: true

class CreateSiphonCiPipelineMetadata < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ci_pipeline_metadata
      (
        project_id Int64,
        pipeline_id Int64 CODEC(DoubleDelta, ZSTD),
        name Nullable(String),
        auto_cancel_on_new_commit Int16 DEFAULT 0,
        auto_cancel_on_job_failure Int16 DEFAULT 0,
        partition_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, pipeline_id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_ci_pipeline_metadata
    SQL
  end
end
