# frozen_string_literal: true

class FinalizeBackfillUsersWithDefaults < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillUsersWithDefaults"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: 'users',
      column_name: 'id',
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
