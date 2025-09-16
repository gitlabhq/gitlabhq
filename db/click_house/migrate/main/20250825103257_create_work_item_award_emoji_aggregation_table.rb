# frozen_string_literal: true

class CreateWorkItemAwardEmojiAggregationTable < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS work_item_award_emoji_aggregations
      (
          work_item_id Int64,
          counts_by_emoji Map(LowCardinality(String), UInt32),
          user_ids_by_emoji Map(LowCardinality(String), String),
          version DateTime64(6, 'UTC') DEFAULT now(),
          deleted Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY work_item_id
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS work_item_award_emoji_aggregations'
  end
end
