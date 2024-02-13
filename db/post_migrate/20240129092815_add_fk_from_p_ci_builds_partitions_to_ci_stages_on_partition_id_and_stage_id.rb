# frozen_string_literal: true

class AddFkFromPCiBuildsPartitionsToCiStagesOnPartitionIdAndStageId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_stages
  COLUMN = :stage_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_3a9eaa254d_p
  PARTITION_COLUMN = :partition_id

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME
    )

    prepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME,
      name: FK_NAME
    )
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME,
      name: FK_NAME
    )

    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      remove_foreign_key_if_exists(
        partition.identifier,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end
end
