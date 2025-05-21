# frozen_string_literal: true

class AddMinimumPauseMsConstraintToBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :batched_background_migration_jobs
  CONSTRAINT_NAME = :check_minimum_pause_ms
  MINIMUM_PAUSE_MS = 100

  def up
    add_check_constraint(
      TABLE_NAME,
      "pause_ms >= #{MINIMUM_PAUSE_MS}",
      check_constraint_name(TABLE_NAME, CONSTRAINT_NAME, 'not_null')
    )
  end

  def down
    remove_check_constraint(
      TABLE_NAME,
      check_constraint_name(TABLE_NAME, CONSTRAINT_NAME, 'not_null')
    )
  end
end
