# frozen_string_literal: true

class CreateContributionsNewV2 < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS contributions_new
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        path String CODEC(ZSTD(3)),
        author_id Int64 CODEC(DoubleDelta, ZSTD),
        target_type LowCardinality(String) DEFAULT '',
        action Int16 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now64(),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(),
        version DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYYYYMM(created_at)
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS contributions_new'
  end
end
