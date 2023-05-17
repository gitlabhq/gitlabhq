# frozen_string_literal: true

class PrepareAuditEventsGroupIndex < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :audit_events
  COLUMN_NAMES = [:entity_id, :entity_type, :created_at, :id]
  INDEX_NAME = 'index_audit_events_on_entity_id_and_entity_type_and_created_at'

  disable_ddl_transaction!

  def up
    # Since audit_events is a partitioned table, we need to prepare the index
    # for each partition individually. We can't use the `prepare_async_index`
    # method directly because it will try to prepare the index for the whole
    # table, which will fail.

    # In a future migration after this one, we will create the index on the
    # parent table itself.
    # TODO: Issue for future migration https://gitlab.com/gitlab-org/gitlab/-/issues/411129
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
