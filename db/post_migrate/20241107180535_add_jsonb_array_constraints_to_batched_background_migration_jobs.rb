# frozen_string_literal: true

class AddJsonbArrayConstraintsToBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_check_constraint :batched_background_migration_jobs,
      "jsonb_typeof(min_cursor) = 'array' AND jsonb_typeof(max_cursor) = 'array'",
      check_constraint_name(:batched_background_migration_jobs, 'cursors', 'jsonb_array')
  end

  def down
    remove_check_constraint :batched_background_migration_jobs,
      check_constraint_name(:batched_background_migration_jobs, 'cursors', 'jsonb_array')
  end
end
