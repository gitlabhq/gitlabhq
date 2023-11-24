# frozen_string_literal: true

class DropIndexProjectRelationExportsOnProjectExportJobId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_project_relation_exports_on_project_export_job_id
  TABLE_NAME = :project_relation_exports

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :project_export_job_id, name: INDEX_NAME
  end
end
