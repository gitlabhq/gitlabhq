# frozen_string_literal: true

class PrepareBuildsMetadataAsyncIdx < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'p_ci_builds_metadata_on_runner_machine_id_idx'

  def up
    # Break up the logic from add_concurrent_partitioned_index so that the partition indices can be created async
    # A follow-up migration will complete the index creation by creating the index on the metadata table, and
    # creating the concurrent foreign key
    each_partition(:p_ci_builds_metadata) do |partition, partition_index_name|
      prepare_async_index(partition.identifier, :runner_machine_id,
                          name: partition_index_name, where: 'runner_machine_id IS NOT NULL')
    end
  end

  def down
    each_partition(:p_ci_builds_metadata) do |partition, partition_index_name|
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
