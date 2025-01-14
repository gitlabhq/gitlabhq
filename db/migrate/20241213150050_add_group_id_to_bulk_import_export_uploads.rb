# frozen_string_literal: true

class AddGroupIdToBulkImportExportUploads < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :bulk_import_export_uploads, :group_id, :bigint
  end
end
