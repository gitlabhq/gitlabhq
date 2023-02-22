# frozen_string_literal: true

class AddBatchIdToBulkImportExportUploads < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_import_export_uploads, :batch_id, :bigint
  end
end
