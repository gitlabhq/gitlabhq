# frozen_string_literal: true

class RemoveUniqueIndexOnProjectExportJobs < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_export_jobs_on_jid'

  def up
    remove_concurrent_index_by_name :project_export_jobs, INDEX_NAME
  end

  def down
    add_concurrent_index :project_export_jobs, :jid, unique: true, name: INDEX_NAME
  end
end
