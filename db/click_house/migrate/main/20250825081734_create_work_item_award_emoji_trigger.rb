# frozen_string_literal: true

class CreateWorkItemAwardEmojiTrigger < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS work_item_award_emoji_trigger (
        work_item_id Int64,
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY work_item_id
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS work_item_award_emoji_trigger_mv to work_item_award_emoji_trigger AS
      SELECT DISTINCT work_item_id FROM work_item_award_emoji
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS work_item_award_emoji_trigger_mv'
    execute 'DROP TABLE IF EXISTS work_item_award_emoji_trigger'
  end
end
