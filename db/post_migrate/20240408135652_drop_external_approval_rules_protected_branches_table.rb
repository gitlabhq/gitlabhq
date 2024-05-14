# frozen_string_literal: true

class DropExternalApprovalRulesProtectedBranchesTable < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  enable_lock_retries!

  def up
    drop_table :external_approval_rules_protected_branches
  end

  def down
    create_table :external_approval_rules_protected_branches do |t|
      t.bigint :external_approval_rule_id, index: { name: 'idx_eaprpb_external_approval_rule_id' }, null: false
      t.bigint :protected_branch_id, null: false
      t.index [:protected_branch_id, :external_approval_rule_id],
        name: 'idx_protected_branch_id_external_approval_rule_id', unique: true
    end
  end
end
