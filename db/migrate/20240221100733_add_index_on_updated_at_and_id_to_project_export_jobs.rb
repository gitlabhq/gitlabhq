# frozen_string_literal: true

class AddIndexOnUpdatedAtAndIdToProjectExportJobs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  TABLE_NAME = :project_export_jobs
  INDEX_NAME = 'index_project_export_jobs_on_updated_at_and_id'

  def up
    add_concurrent_index TABLE_NAME, [:updated_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
