# frozen_string_literal: true

class FinalizeCorrectDesignManagementDesignsBackfill < Gitlab::Database::Migration[2.3]
  MIGRATION = "BackfillDesignManagementDesignsProjectNamespaceId"

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!
  milestone '18.5'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :design_management_designs,
      column_name: :id,
      job_arguments: [],
      finalize: true,
      skip_early_finalization_validation: true
    )
  end

  def down; end
end
