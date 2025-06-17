# frozen_string_literal: true

class AddIdxApprovalPolicyRuleProjectLinksOnProjectIdAndId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_approval_policy_rule_project_links_on_project_id_and_id'

  def up
    add_concurrent_index :approval_policy_rule_project_links, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_policy_rule_project_links, INDEX_NAME
  end
end
