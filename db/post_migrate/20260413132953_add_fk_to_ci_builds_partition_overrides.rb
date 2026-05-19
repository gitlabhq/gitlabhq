# frozen_string_literal: true

class AddFkToCiBuildsPartitionOverrides < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '19.0'

  # rubocop: disable Migration/PreventForeignKeyCreation -- it's 1% of the records that will have a record in this table
  def up
    add_concurrent_partitioned_foreign_key(
      :p_ci_builds_partition_overrides, :p_ci_builds,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end
  # rubocop: enable Migration/PreventForeignKeyCreation

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :p_ci_builds_partition_overrides, :p_ci_builds,
        column: [:partition_id, :build_id],
        reverse_lock_order: true
      )
    end
  end
end
