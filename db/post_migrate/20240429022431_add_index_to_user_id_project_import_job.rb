# frozen_string_literal: true

class AddIndexToUserIdProjectImportJob < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  INDEX_NAME = :index_project_export_jobs_on_user_id

  def up
    add_concurrent_index :project_export_jobs, :user_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_export_jobs, INDEX_NAME
  end
end
