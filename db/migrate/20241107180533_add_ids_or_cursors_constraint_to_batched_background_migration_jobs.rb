# frozen_string_literal: true

class AddIdsOrCursorsConstraintToBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_check_constraint :batched_background_migration_jobs,
      'num_nonnulls(min_value, max_value) = 2 OR num_nonnulls(min_cursor, max_cursor) = 2',
      check_constraint_name(:batched_background_migration_jobs, 'ids_or_cursors', 'not_null')
  end

  def down
    remove_check_constraint :batched_background_migration_jobs,
      check_constraint_name(:batched_background_migration_jobs, 'ids_or_cursors', 'not_null')
  end
end
