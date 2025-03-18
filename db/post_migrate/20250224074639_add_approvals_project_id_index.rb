# frozen_string_literal: true

class AddApprovalsProjectIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  INDEX_NAME = 'index_approvals_on_project_id'

  def up
    add_concurrent_index :approvals, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approvals, INDEX_NAME
  end
end
