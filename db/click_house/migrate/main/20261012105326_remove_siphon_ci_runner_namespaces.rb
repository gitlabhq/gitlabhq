# frozen_string_literal: true

# Not replicated since its Siphon configuration was removed in May 2026. The drop loses no data:
# Siphon snapshots the table again from PostgreSQL once replication is configured. The next
# migration recreates it with the current Siphon generator definition.
class RemoveSiphonCiRunnerNamespaces < ClickHouse::Migration
  def up
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_ci_runner_namespaces
    SQL
  end

  def down
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_ci_runner_namespaces
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        runner_id Int64,
        namespace_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
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
end
