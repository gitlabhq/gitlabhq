# frozen_string_literal: true

class AddFkFromCiRunnerControllerRunnerLevelScopingsToCiRunnerControllers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '18.9'

  SOURCE_TABLE_NAME = :ci_runner_controller_runner_level_scopings
  TARGET_TABLE_NAME = :ci_runner_controllers
  COLUMN_NAME = :runner_controller_id

  def up
    add_concurrent_partitioned_foreign_key SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN_NAME,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, column: COLUMN_NAME
    end
  end
end
