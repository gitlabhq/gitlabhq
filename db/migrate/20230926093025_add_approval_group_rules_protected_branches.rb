# frozen_string_literal: true

class AddApprovalGroupRulesProtectedBranches < Gitlab::Database::Migration[2.1]
  INDEX_RULE_PROTECTED_BRANCH = 'idx_on_approval_group_rules_protected_branch'
  INDEX_APPROVAL_GROUP_RULE = 'idx_on_approval_group_rules'
  INDEX_PROTECTED_BRANCH = 'idx_on_protected_branch'

  def up
    create_table :approval_group_rules_protected_branches do |t|
      t.bigint :approval_group_rule_id, null: false
      t.bigint :protected_branch_id, null: false

      t.index :protected_branch_id, name: INDEX_PROTECTED_BRANCH
      t.index [:approval_group_rule_id, :protected_branch_id], unique: true, name: INDEX_RULE_PROTECTED_BRANCH
    end
  end

  def down
    drop_table :approval_group_rules_protected_branches
  end
end
