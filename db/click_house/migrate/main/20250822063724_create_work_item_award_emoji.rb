# frozen_string_literal: true

class CreateWorkItemAwardEmoji < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS work_item_award_emoji
      (
        work_item_id Int64,
        id Int64,
        name LowCardinality(String),
        user_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (work_item_id, id)
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS work_item_award_emoji_mv
      TO work_item_award_emoji
      AS
      SELECT
        awardable_id AS work_item_id,
        id,
        name,
        user_id,
        created_at,
        updated_at,
        _siphon_replicated_at AS version,
        _siphon_deleted AS deleted
      FROM siphon_award_emoji
      WHERE awardable_type = 'Issue'
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS work_item_award_emoji_mv
    SQL

    execute <<-SQL
      DROP TABLE IF EXISTS work_item_award_emoji
    SQL
  end
end
