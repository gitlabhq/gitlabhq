# frozen_string_literal: true

class IndexApprovalProjectRulesUsersOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_project_rules_users_on_project_id'

  def up
    add_concurrent_index :approval_project_rules_users, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_project_rules_users, INDEX_NAME
  end
end
