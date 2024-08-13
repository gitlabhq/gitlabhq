# frozen_string_literal: true

class CreateApprovalPolicyRuleProjectLinks < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  INDEX_NAME = 'index_approval_policy_rule_on_project_and_rule'

  def up
    create_table :approval_policy_rule_project_links do |t|
      t.bigint :project_id, null: false, index: true
      t.bigint :approval_policy_rule_id, null: false

      t.index [:approval_policy_rule_id, :project_id], unique: true, name: INDEX_NAME
    end
  end

  def down
    drop_table :approval_policy_rule_project_links
  end
end
