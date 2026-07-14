# frozen_string_literal: true

class CreateSiphonSbomOccurrences < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_sbom_occurrences
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        component_version_id Nullable(Int64),
        project_id Int64,
        pipeline_id Nullable(Int64),
        source_id Nullable(Int64),
        commit_sha String,
        component_id Int64,
        uuid UUID,
        package_manager Nullable(String),
        component_name Nullable(String),
        input_file_path Nullable(String),
        licenses Nullable(String) DEFAULT '[]',
        highest_severity Nullable(Int16),
        vulnerability_count Int64 DEFAULT 0,
        source_package_id Nullable(Int64),
        archived Bool DEFAULT false CODEC(ZSTD(1)),
        traversal_ids Array(Int64) DEFAULT [],
        ancestors String DEFAULT '[]',
        reachability Nullable(Int16) DEFAULT 0,
        partition_id Nullable(Int64) DEFAULT 1,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_sbom_occurrences
    SQL
  end
end
