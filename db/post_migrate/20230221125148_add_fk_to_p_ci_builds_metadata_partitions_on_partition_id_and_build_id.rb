# frozen_string_literal: true

class AddFkToPCiBuildsMetadataPartitionsOnPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds_metadata
  TARGET_TABLE_NAME = :ci_builds
  COLUMN = :build_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_e20479742e_p
  PARTITION_COLUMN = :partition_id

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      add_concurrent_foreign_key(
        partition.identifier,
        TARGET_TABLE_NAME,
        column: [PARTITION_COLUMN, COLUMN],
        target_column: [PARTITION_COLUMN, TARGET_COLUMN],
        validate: false,
        reverse_lock_order: true,
        on_update: :cascade,
        on_delete: :cascade,
        name: FK_NAME
      )
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier,
          TARGET_TABLE_NAME,
          name: FK_NAME,
          reverse_lock_order: true
        )
      end
    end
  end
end
