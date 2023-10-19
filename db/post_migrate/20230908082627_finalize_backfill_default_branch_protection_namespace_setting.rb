# frozen_string_literal: true

class FinalizeBackfillDefaultBranchProtectionNamespaceSetting < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillDefaultBranchProtectionNamespaceSetting'

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
