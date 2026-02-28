# frozen_string_literal: true

class CreateSiphonSecurityScans < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_security_scans
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        build_id Int64,
        scan_type Int16,
        info String DEFAULT '{}',
        project_id Int64,
        pipeline_id Nullable(Int64),
        latest Bool DEFAULT true CODEC(ZSTD(1)),
        status Int16 DEFAULT 0,
        findings_partition_number Int64 DEFAULT 1,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
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
      DROP TABLE IF EXISTS siphon_security_scans
    SQL
  end
end
