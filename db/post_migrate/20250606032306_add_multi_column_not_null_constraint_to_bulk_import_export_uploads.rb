# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToBulkImportExportUploads < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:bulk_import_export_uploads, :project_id, :group_id)
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_export_uploads, :project_id, :group_id)
  end
end
