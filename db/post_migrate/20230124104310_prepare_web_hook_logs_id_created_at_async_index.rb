# frozen_string_literal: true

class PrepareWebHookLogsIdCreatedAtAsyncIndex < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_web_hook_logs_on_web_hook_id_and_created_at'

  def up
    # Since web_hook_logs is a partitioned table, we need to prepare the index
    # for each partition individually. We can't use the `prepare_async_index`
    # method directly because it will try to prepare the index for the whole
    # table, which will fail.

    # In a future migration after this one, we will create the index on the
    # parent table itself.
    each_partition(:web_hook_logs) do |partition, partition_index_name|
      prepare_async_index(partition.identifier, [:web_hook_id, :created_at],
                          name: partition_index_name)
    end
  end

  def down
    each_partition(:web_hook_logs) do |partition, partition_index_name|
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
