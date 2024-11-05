# frozen_string_literal: true

class RetryRevertAddFkFromPartitionedCiRunnerManagersToPartitionedCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_runner_machines_687967fa8a
  TARGET_TABLE_NAME = :ci_runners_e59bb2812d
  FK_NAME = :fk_rails_3f92913d27

  def up
    # Remove the partitioned tables' FK, since it wasn't handled automatically
    # by RevertAddFkFromPartitionedCiRunnerManagersToPartitionedCiRunners
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      source = partition.to_s

      with_lock_retries do
        remove_foreign_key_if_exists(source, partitioned_target_table_name(source),
          name: FK_NAME, reverse_lock_order: true)
      end
    end
  end

  def down
    # no-op
  end

  private

  def partitioned_target_table_name(source)
    runner_type = source.match(/(.+?_type).+/)[1]
    "#{runner_type}_#{TARGET_TABLE_NAME}"
  end
end
