# frozen_string_literal: true

class DropIndexApprovalPolicyRuleProjectLinksOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_policy_rule_project_links_on_project_id'

  def up
    remove_concurrent_index_by_name :approval_policy_rule_project_links, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_policy_rule_project_links, :project_id, name: INDEX_NAME
  end
end
