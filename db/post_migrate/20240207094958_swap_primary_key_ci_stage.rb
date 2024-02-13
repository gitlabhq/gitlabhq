# frozen_string_literal: true

class SwapPrimaryKeyCiStage < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  PRIMARY_KEY = :ci_stages_pkey
  NEW_INDEX = :index_ci_stages_on_id_partition_id_unique
  OLD_INDEX = :index_ci_stages_on_id_unique

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX)

    recreate_partitioned_foreign_keys
  end

  private

  def recreate_partitioned_foreign_keys
    add_partitioned_fk(:p_ci_builds, :fk_3a9eaa254d_p, column: :stage_id)
  end

  def add_partitioned_fk(source_table, name, column: nil)
    add_concurrent_partitioned_foreign_key(
      source_table,
      TABLE_NAME,
      column: [:partition_id, column],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: name
    )
  end
end
