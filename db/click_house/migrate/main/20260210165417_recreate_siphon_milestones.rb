# frozen_string_literal: true

class RecreateSiphonMilestones < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_milestones
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        title String CODEC(ZSTD(3)),
        project_id Nullable(Int64),
        description String CODEC(ZSTD(3)),
        due_date Nullable(Date32),
        created_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(Delta, ZSTD(1)),
        state LowCardinality(String),
        iid Int64,
        start_date Nullable(Date32),
        group_id Nullable(Int64),
        lock_version Int64 DEFAULT 0,
        traversal_path String DEFAULT multiIf(
          coalesce(project_id, 0) != 0,
          dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
          coalesce(group_id, 0) != 0,
          dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)),
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
      DROP TABLE IF EXISTS siphon_milestones
    SQL
  end
end
