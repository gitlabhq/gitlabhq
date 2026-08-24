# frozen_string_literal: true

class CreateSiphonAiCatalogItems < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ai_catalog_items
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        organization_id Int64,
        project_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        item_type Int16,
        description String,
        name String,
        public Bool DEFAULT false CODEC(ZSTD(1)),
        deleted_at Nullable(DateTime64(6, 'UTC')),
        latest_version_id Nullable(Int64),
        latest_released_version_id Nullable(Int64),
        verification_level Int16 DEFAULT 0,
        identifier Nullable(String),
        foundational_flow_reference Nullable(String),
        last_30_day_usage_count Int64 DEFAULT 0,
        last_30_day_usage_count_updated_at DateTime64(6, 'UTC') DEFAULT '1970-01-01 00:00:00',
        star_count Int64 DEFAULT 0,
        visibility Int16 DEFAULT 0,
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
      DROP TABLE IF EXISTS siphon_ai_catalog_items
    SQL
  end
end
