# frozen_string_literal: true

class AllowNullProjectIdOnBulkImportExportUploadUploadStates < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  TABLE_NAME = :bulk_import_export_upload_upload_states

  def up
    change_column_null TABLE_NAME, :project_id, true
  end

  def down
    change_column_null TABLE_NAME, :project_id, false
  end
end
