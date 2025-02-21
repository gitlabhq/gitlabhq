# frozen_string_literal: true

class IndexProjectRelationExportUploadsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_relation_export_uploads_on_project_id'

  def up
    add_concurrent_index :project_relation_export_uploads, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_relation_export_uploads, INDEX_NAME
  end
end
