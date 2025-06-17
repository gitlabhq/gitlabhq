# frozen_string_literal: true

class FinalizeBackfillBulkImportExportUploadsGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBulkImportExportUploadsGroupId',
      table_name: :bulk_import_export_uploads,
      column_name: :id,
      job_arguments: [
        :group_id,
        :bulk_import_exports,
        :group_id,
        :export_id
      ],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
