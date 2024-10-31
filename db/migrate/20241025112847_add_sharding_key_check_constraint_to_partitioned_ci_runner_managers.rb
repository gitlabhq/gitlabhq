# frozen_string_literal: true

class AddShardingKeyCheckConstraintToPartitionedCiRunnerManagers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  PARTITIONED_TABLE_NAME = :ci_runner_machines_687967fa8a
  CONSTRAINT_NAME = 'check_sharding_key_id_nullness'

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(PARTITIONED_TABLE_NAME) do |partition|
      source = partition.to_s

      add_check_constraint(source,
        source.start_with?('instance_type') ? 'sharding_key_id IS NULL' : 'sharding_key_id IS NOT NULL',
        CONSTRAINT_NAME)
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(PARTITIONED_TABLE_NAME) do |partition|
      source = partition.to_s

      remove_check_constraint(source, CONSTRAINT_NAME)
    end
  end
end
