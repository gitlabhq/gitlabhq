# frozen_string_literal: true

class CreateSiphonLabels < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_labels
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        title String CODEC(ZSTD(3)),
        color String,
        project_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        template Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
        description String CODEC(ZSTD(3)),
        type LowCardinality(String),
        group_id Nullable(Int64),
        lock_on_merge Bool DEFAULT false CODEC(ZSTD(1)),
        archived Bool DEFAULT false CODEC(ZSTD(1)),
        organization_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(
          coalesce(group_id, 0) != 0,
          dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'),
          coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
          coalesce(organization_id, 0) != 0, dictGetOrDefault('organization_traversal_paths_dict', 'traversal_path', organization_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)), -- there is no database constraint on having one of group_id, project_id, or organization_id be non-null
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_labels
    SQL
  end
end
