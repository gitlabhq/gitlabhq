# frozen_string_literal: true

class RemoveOldAiUsageEventsEventIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.4'
  disable_ddl_transaction!

  INDEX_NAME = :index_ai_usage_events_on_namespace_id_timestamp_and_id

  # rubocop:disable Migration/Datetime -- it's a column name
  def up
    remove_concurrent_partitioned_index_by_name(:ai_usage_events, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index :ai_usage_events,
      [:namespace_id, :timestamp, :id],
      name: INDEX_NAME
  end
  # rubocop:enable Migration/Datetime
end
