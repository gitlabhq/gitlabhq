# frozen_string_literal: true

class ValidatePartitioningConstraintOnMetadataPartitions < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds_metadata

  def up
    return unless Gitlab.com_except_jh?

    each_partition do |partition|
      prepare_async_check_constraint_validation(partition.identifier, name: constraint_name(partition))
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    each_partition do |partition|
      unprepare_async_check_constraint_validation(partition.identifier, name: constraint_name(partition))
    end
  end

  private

  def each_partition
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME).to_a.reverse_each do |partition|
      ids = partition.condition.scan(/\d+/).map(&:to_i)
      next if (ids & [100, 101, 102]).any?

      yield(partition)
    end
  end

  def constraint_name(partition)
    check_constraint_name(partition.identifier, 'partition_id', 'partition')
  end
end
