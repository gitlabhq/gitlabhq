# frozen_string_literal: true

class AddProjectIdToBulkImportExportUploads < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :bulk_import_export_uploads, :project_id, :bigint
  end
end
