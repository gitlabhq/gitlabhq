# frozen_string_literal: true

class CreateSiphonSecurityFindings < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_security_findings
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        scan_id Int64,
        scanner_id Int64,
        severity Int16,
        deduplicated Bool DEFAULT false CODEC(ZSTD(1)),
        uuid UUID,
        overridden_uuid Nullable(UUID),
        partition_number Int64 DEFAULT 1,
        finding_data String DEFAULT '{}',
        project_id Int64 DEFAULT 0,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id, partition_number
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id, partition_number)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_security_findings
    SQL
  end
end
