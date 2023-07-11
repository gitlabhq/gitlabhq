# frozen_string_literal: true

class FinalizeUserTypeMigration < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateHumanUserType'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :users,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
