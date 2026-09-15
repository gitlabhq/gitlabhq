# frozen_string_literal: true

class CleanupBulkImportExportUploadUploadStatesWithNullProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  class BulkImportExportUploadUploadState < MigrationRecord
    include EachBatch

    self.table_name = 'bulk_import_export_upload_upload_states'
  end

  def up
    # no-op - this migration is required to allow a rollback of
    # `AllowNullProjectIdOnBulkImportExportUploadUploadStates`
  end

  def down
    # Group-owned rows have a null project_id, which blocks both the NOT NULL
    # constraint restored by 20260819155602 and the check constraint added back
    # by 20260819155600 on a later re-run. Geo::VerificationStateBackfillService
    # recreates these rows, so deleting them only costs a re-verification.
    BulkImportExportUploadUploadState.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(project_id: nil).delete_all
    end
  end
end
