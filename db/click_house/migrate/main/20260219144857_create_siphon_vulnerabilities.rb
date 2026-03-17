# frozen_string_literal: true

class CreateSiphonVulnerabilities < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_vulnerabilities
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        project_id Int64,
        author_id Int64,
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        title String CODEC(ZSTD(1)),
        description String DEFAULT '' CODEC(ZSTD(3)),
        state Int16 DEFAULT 1,
        severity Int16,
        severity_overridden Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
        resolved_by_id Nullable(Int64),
        resolved_at Nullable(DateTime64(6, 'UTC')),
        report_type Int16,
        confirmed_by_id Nullable(Int64),
        confirmed_at Nullable(DateTime64(6, 'UTC')),
        dismissed_at Nullable(DateTime64(6, 'UTC')),
        dismissed_by_id Nullable(Int64),
        resolved_on_default_branch Bool DEFAULT false CODEC(ZSTD(1)),
        present_on_default_branch Bool DEFAULT true CODEC(ZSTD(1)),
        detected_at Nullable(DateTime64(6, 'UTC')) DEFAULT now(),
        finding_id Int64,
        cvss Nullable(String) DEFAULT '[]',
        auto_resolved Bool DEFAULT false CODEC(ZSTD(1)),
        uuid Nullable(UUID),
        solution Nullable(String),
        partition_id Nullable(Int64) DEFAULT 1,
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
      DROP TABLE IF EXISTS siphon_vulnerabilities
    SQL
  end
end
