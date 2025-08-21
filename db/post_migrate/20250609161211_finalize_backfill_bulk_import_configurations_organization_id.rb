# frozen_string_literal: true

class FinalizeBackfillBulkImportConfigurationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBulkImportConfigurationsOrganizationId',
      table_name: :bulk_import_configurations,
      column_name: :id,
      job_arguments: [:organization_id, :bulk_imports, :organization_id, :bulk_import_id],
      finalize: true
    )
  end

  def down; end
end
