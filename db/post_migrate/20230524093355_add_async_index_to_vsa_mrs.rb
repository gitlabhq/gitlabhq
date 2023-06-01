# frozen_string_literal: true

class AddAsyncIndexToVsaMrs < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :analytics_cycle_analytics_merge_request_stage_events
  COLUMN_NAMES = %I[stage_event_hash_id group_id end_event_timestamp merge_request_id]
  INDEX_NAME = 'index_mr_stage_events_for_consistency_check'

  disable_ddl_transaction!

  def up
    # The table is hash partitioned
    each_partition(TABLE_NAME) do |partition, partition_index_name|
      prepare_async_index(
        partition.identifier,
        COLUMN_NAMES,
        name: partition_index_name
      )
    end
  end

  def down
    each_partition(TABLE_NAME) do |partition, partition_index_name|
      unprepare_async_index_by_name(partition.identifier, partition_index_name)
    end
  end

  private

  def each_partition(table_name)
    partitioned_table = find_partitioned_table(table_name)
    partitioned_table.postgres_partitions.order(:name).each do |partition|
      partition_index_name = generated_index_name(partition.identifier, INDEX_NAME)

      yield partition, partition_index_name
    end
  end
end
