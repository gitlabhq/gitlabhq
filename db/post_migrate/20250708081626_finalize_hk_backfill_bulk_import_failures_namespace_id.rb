# frozen_string_literal: true

class FinalizeHkBackfillBulkImportFailuresNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBulkImportFailuresNamespaceId',
      table_name: :bulk_import_failures,
      column_name: :id,
      job_arguments: [:namespace_id, :bulk_import_entities, :namespace_id, :bulk_import_entity_id],
      finalize: true
    )
  end

  def down; end
end
