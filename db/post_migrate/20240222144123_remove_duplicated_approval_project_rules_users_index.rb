# frozen_string_literal: true

class RemoveDuplicatedApprovalProjectRulesUsersIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'index_approval_project_rules_users_on_approval_project_rule_id'

  def up
    remove_concurrent_index_by_name :approval_project_rules_users, name: INDEX_NAME
  end

  def down
    add_concurrent_index :approval_project_rules_users, :approval_project_rule_id, name: INDEX_NAME
  end
end
