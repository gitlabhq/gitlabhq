# frozen_string_literal: true

class CreateSiphonWorkItemParentLinks < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_work_item_parent_links
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        work_item_id Int64,
        work_item_parent_id Int64 CODEC(DoubleDelta, ZSTD),
        relative_position Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        namespace_id Int64, -- check_e9c0111985 enforces that namespace_id can never be null
        traversal_path String DEFAULT multiIf(
          coalesce(namespace_id, 0) != 0,
          dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'),
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
      PRIMARY KEY (traversal_path, work_item_parent_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_work_item_parent_links
    SQL
  end
end
