# frozen_string_literal: true

class AddNamespaceTimestampIdIndexForAiUsageEvents < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :ai_usage_events
  COLUMN_NAMES = [:namespace_id, :timestamp, :id]

  INDEX_NAME = :index_ai_usage_events_on_namespace_id_timestamp_and_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
