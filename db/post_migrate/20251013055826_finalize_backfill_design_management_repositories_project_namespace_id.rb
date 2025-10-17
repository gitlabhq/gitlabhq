# frozen_string_literal: true

class FinalizeBackfillDesignManagementRepositoriesProjectNamespaceId < Gitlab::Database::Migration[2.3]
  MIGRATION = "BackfillDesignManagementRepositoriesProjectNamespaceId"

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '18.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :design_management_repositories,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
