# frozen_string_literal: true

class FinalizeMigrateProjectAuthorizations < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MigrateProjectAuthorizations',
      table_name: :project_authorizations,
      column_name: :user_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
