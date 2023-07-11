# frozen_string_literal: true

class FinishUserTypeMigration < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateHumanUserType'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

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
