# frozen_string_literal: true

class FinalizeHkBackfillBulkImportFailuresOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBulkImportFailuresOrganizationId',
      table_name: :bulk_import_failures,
      column_name: :id,
      job_arguments: [:organization_id, :bulk_import_entities, :organization_id, :bulk_import_entity_id],
      finalize: true
    )
  end

  def down; end
end
