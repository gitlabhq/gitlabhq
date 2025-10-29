# frozen_string_literal: true

class AddProjectExportJobsUniqueIndexOnJidProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_export_jobs_on_jid_and_project_id'

  def up
    add_concurrent_index :project_export_jobs, %i[jid project_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_export_jobs, INDEX_NAME
  end
end
