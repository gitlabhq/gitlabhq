# frozen_string_literal: true

class AddNotNullConstraintOnBulkImportExportUploadUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_multi_column_not_null_constraint(:bulk_import_export_upload_uploads, :project_id, :namespace_id)
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_export_upload_uploads, :project_id, :namespace_id)
  end
end
