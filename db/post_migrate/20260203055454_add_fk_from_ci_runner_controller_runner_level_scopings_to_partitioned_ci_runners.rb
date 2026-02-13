# frozen_string_literal: true

class AddFkFromCiRunnerControllerRunnerLevelScopingsToPartitionedCiRunners < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '18.9'

  SOURCE_TABLE_NAME = :ci_runner_controller_runner_level_scopings
  TARGET_TABLE_NAME = :ci_runners
  COLUMN = %i[runner_id runner_type]
  TARGET_COLUMN = %i[id runner_type]
  FK_NAME = :fk_ci_rcrl_scopings_runner_id_runner_type

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      name: FK_NAME,
      target_column: TARGET_COLUMN,
      validate: true,
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    remove_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      name: FK_NAME,
      reverse_lock_order: true
    )
  end
end
