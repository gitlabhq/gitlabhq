# frozen_string_literal: true

class AttachCustomLfkTriggerToCiBuildsPartitions < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  disable_ddl_transaction!

  milestone '17.9'

  PARTITIONED_TABLE = :p_ci_builds

  def up
    partitioned_table_identifier = "#{current_schema}.#{PARTITIONED_TABLE}"

    # Partitions
    Gitlab::Database::PostgresPartitionedTable.each_partition(PARTITIONED_TABLE) do |partition|
      with_lock_retries do
        untrack_record_deletions(partition.identifier)
        track_record_deletions_override_table_name(partition.identifier, PARTITIONED_TABLE)
      end
    end

    # Reattaching the new trigger function to the existing partitioned tables
    # but with an overridden table name
    with_lock_retries do
      untrack_record_deletions(PARTITIONED_TABLE)
      track_record_deletions_override_table_name(partitioned_table_identifier)
    end
  end

  def down
    # Partitions
    Gitlab::Database::PostgresPartitionedTable.each_partition(PARTITIONED_TABLE) do |partition|
      with_lock_retries do
        untrack_record_deletions(partition.identifier)

        if partition.schema == current_schema # the triggers were only on the default schema partitions
          track_record_deletions(partition.name) # re-attach the old trigger
        end
      end
    end

    # Partitioned tables
    with_lock_retries do
      untrack_record_deletions(PARTITIONED_TABLE)
      track_record_deletions(PARTITIONED_TABLE) # re-attach the old trigger
    end
  end
end
