# frozen_string_literal: true

class AddUniqueIndexOnProjectImportExportRelationExportUploadUploadsIdV2 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  PARTITION_TABLE_NAME = :project_import_export_relation_export_upload_uploads
  PARTITION_INDEX_NAME = :idx_project_import_export_relation_export_upload_uploads_on_id

  def up
    add_concurrent_index PARTITION_TABLE_NAME, :id, unique: true, name: PARTITION_INDEX_NAME, allow_partition: true
  end

  def down
    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{PARTITION_INDEX_NAME}"
    end
  end
end
