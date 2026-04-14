# frozen_string_literal: true

class CreateSiphonWorkItemCurrentStatusesV2 < ClickHouse::Migration
  def up
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_work_item_current_statuses
    SQL

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_work_item_current_statuses
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        namespace_id Int64,
        work_item_id Int64 CODEC(ZSTD(1)),
        system_defined_status_id Nullable(Int64),
        custom_status_id Nullable(Int64),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6) CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, work_item_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_work_item_current_statuses
    SQL

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_work_item_current_statuses
      (
        id Int64,
        namespace_id Int64,
        work_item_id Int64,
        system_defined_status_id Int64,
        custom_status_id Int64,
        updated_at DateTime64(6, 'UTC'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (work_item_id, id)
    SQL
  end
end
