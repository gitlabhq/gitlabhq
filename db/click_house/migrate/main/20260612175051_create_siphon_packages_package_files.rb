# frozen_string_literal: true

class CreateSiphonPackagesPackageFiles < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_packages_package_files
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        package_id Int64,
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        size Nullable(Int64),
        file_store Int64 DEFAULT 1,
        file_md5 Nullable(String),
        file_sha1 Nullable(String),
        file_name String,
        file String,
        file_sha256 Nullable(String),
        verification_retry_at Nullable(DateTime64(6, 'UTC')),
        verified_at Nullable(DateTime64(6, 'UTC')),
        verification_failure Nullable(String),
        verification_retry_count Nullable(Int64),
        verification_checksum Nullable(String),
        verification_state Int16 DEFAULT 0,
        verification_started_at Nullable(DateTime64(6, 'UTC')),
        status Int16 DEFAULT 0,
        file_final_path Nullable(String),
        project_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      ORDER BY (traversal_path, id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_packages_package_files
    SQL
  end
end
