# frozen_string_literal: true

class CreateSiphonMergeRequestReviewers < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_request_reviewers
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        user_id Int64,
        merge_request_id Int64 CODEC(ZSTD(1)),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        state Int16 DEFAULT 0,
        project_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, merge_request_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_request_reviewers
    SQL
  end
end
