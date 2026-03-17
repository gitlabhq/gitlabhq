# frozen_string_literal: true

class CreateSiphonAwardEmojiV2 < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_award_emoji
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        name LowCardinality(String) CODEC(LZ4),
        user_id Int64,
        awardable_type LowCardinality(String) CODEC(LZ4),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        awardable_id Int64 CODEC(ZSTD(1)),
        namespace_id Nullable(Int64),
        organization_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), coalesce(organization_id, 0) != 0, dictGetOrDefault('organization_traversal_paths_dict', 'traversal_path', organization_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, awardable_type, awardable_id, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_award_emoji
    SQL
  end
end
