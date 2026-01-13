# frozen_string_literal: true

class AddPartitionConstraintsNotValidToCiBuildsMetadataPartitions < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds_metadata

  def up
    return unless Gitlab.com_except_jh?

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      ids = partition.condition.scan(/\d+/).map(&:to_i)

      add_check_constraint(
        partition.identifier,
        "partition_id = ANY(ARRAY[#{ids.join(', ')}])",
        constraint_name(partition),
        validate: false
      )
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      remove_check_constraint(partition.identifier, constraint_name(partition))
    end
  end

  private

  def constraint_name(partition)
    check_constraint_name(partition.identifier, 'partition_id', 'partition')
  end
end
