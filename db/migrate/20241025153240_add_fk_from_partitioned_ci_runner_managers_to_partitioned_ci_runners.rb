# frozen_string_literal: true

class AddFkFromPartitionedCiRunnerManagersToPartitionedCiRunners < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.6'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_runner_machines_687967fa8a
  TARGET_TABLE_NAME = :ci_runners_e59bb2812d
  COLUMN = %i[runner_id runner_type]
  TARGET_COLUMN = %i[id runner_type]
  FK_NAME = :fk_rails_3f92913d27

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      add_partitioned_foreign_key(partition)
    end

    add_concurrent_foreign_key(SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      name: FK_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      validate: true,
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      allow_partitioned: true)
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      source = partition.to_s

      with_lock_retries do
        remove_foreign_key_if_exists(source, partitioned_target_table_name(source),
          name: FK_NAME, reverse_lock_order: true)
      end
    end

    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
        name: FK_NAME, reverse_lock_order: true)
    end
  end

  private

  def partitioned_target_table_name(source)
    runner_type = source.match(/(.+?_type).+/)[1]
    "#{runner_type}_#{TARGET_TABLE_NAME}"
  end

  def add_partitioned_foreign_key(partition)
    source = partition.to_s
    add_concurrent_foreign_key(source, partitioned_target_table_name(source),
      name: FK_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      validate: true,
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true)
  end
end
