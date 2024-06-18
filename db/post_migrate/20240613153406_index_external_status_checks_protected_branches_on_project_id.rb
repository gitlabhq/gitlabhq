# frozen_string_literal: true

class IndexExternalStatusChecksProtectedBranchesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_external_status_checks_protected_branches_on_project_id'

  def up
    add_concurrent_index :external_status_checks_protected_branches, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :external_status_checks_protected_branches, INDEX_NAME
  end
end
