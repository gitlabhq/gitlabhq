# frozen_string_literal: true

class CreateSiphonContainerRepositories < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_container_repositories
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        project_id Int64,
        name String,
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        status Nullable(Int16),
        expiration_policy_started_at Nullable(DateTime64(6, 'UTC')),
        expiration_policy_cleanup_status Int16 DEFAULT 0,
        expiration_policy_completed_at Nullable(DateTime64(6, 'UTC')),
        last_cleanup_deleted_tags_count Nullable(Int64),
        delete_started_at Nullable(DateTime64(6, 'UTC')),
        status_updated_at Nullable(DateTime64(6, 'UTC')),
        failed_deletion_count Int64 DEFAULT 0,
        next_delete_attempt_at Nullable(DateTime64(6, 'UTC')),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      ORDER BY (traversal_path, id)
      SETTINGS index_granularity = 2048
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_container_repositories
    SQL
  end
end
