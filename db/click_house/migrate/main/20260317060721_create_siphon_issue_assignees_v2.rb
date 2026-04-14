# frozen_string_literal: true

class CreateSiphonIssueAssigneesV2 < ClickHouse::Migration
  def up
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_issue_assignees
    SQL

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_issue_assignees
      (
        user_id Int64 CODEC(Delta, ZSTD),
        issue_id Int64 CODEC(Delta, ZSTD),
        namespace_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6) CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY issue_id, user_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, issue_id, user_id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_issue_assignees
    SQL

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_issue_assignees
      (
        user_id Int64,
        issue_id Int64,
        namespace_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (issue_id, user_id)
    SQL
  end
end
