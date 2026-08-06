# frozen_string_literal: true

class CreateSiphonSbomComponentVersionsWithTraversalPath < ClickHouse::Migration
  def up
    execute "DROP TABLE IF EXISTS siphon_sbom_component_versions"

    execute <<-SQL
      CREATE TABLE siphon_sbom_component_versions
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        component_id Int64,
        version String,
        source_package_name String,
        organization_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(organization_id, 0) != 0, dictGetOrDefault('organization_traversal_paths_dict', 'traversal_path', organization_id, '0/'), '0/') CODEC(ZSTD(3)),
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
      DROP TABLE IF EXISTS siphon_sbom_component_versions
    SQL

    execute <<-SQL
      CREATE TABLE siphon_sbom_component_versions
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        component_id Int64,
        version String,
        source_package_name Nullable(String),
        organization_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (id)
      SETTINGS index_granularity = 2048
    SQL
  end
end
