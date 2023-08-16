# frozen_string_literal: true

class AddIndexesToExternalStatusChecksOnIdAndProjectId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_external_status_checks_on_id_and_project_id'
  disable_ddl_transaction!

  def up
    add_concurrent_index :external_status_checks, [:id, :project_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :external_status_checks, name: INDEX_NAME
  end
end
