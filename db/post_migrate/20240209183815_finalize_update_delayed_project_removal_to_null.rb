# frozen_string_literal: true

class FinalizeUpdateDelayedProjectRemovalToNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'UpdateDelayedProjectRemovalToNullForUserNamespaces'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :namespace_settings,
      column_name: :namespace_id,
      job_arguments: []
    )
  end

  def down
    # noop
  end
end
