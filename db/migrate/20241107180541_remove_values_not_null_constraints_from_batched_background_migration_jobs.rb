# frozen_string_literal: true

class RemoveValuesNotNullConstraintsFromBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    change_column_null :batched_background_migration_jobs, :max_value, true
    change_column_null :batched_background_migration_jobs, :min_value, true
  end

  def down
    change_column_null :batched_background_migration_jobs, :max_value, false
    change_column_null :batched_background_migration_jobs, :min_value, false
  end
end
