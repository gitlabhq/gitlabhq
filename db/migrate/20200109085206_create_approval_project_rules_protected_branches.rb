# frozen_string_literal: true

class CreateApprovalProjectRulesProtectedBranches < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :approval_project_rules_protected_branches, id: false do |t|
      t.references :approval_project_rule,
                   null: false,
                   index: false,
                   foreign_key: { on_delete: :cascade }
      t.references :protected_branch,
                   null: false,
                   index: { name: 'index_approval_project_rules_protected_branches_pb_id' },
                   foreign_key: { on_delete: :cascade }
      t.index [:approval_project_rule_id, :protected_branch_id], name: 'index_approval_project_rules_protected_branches_unique', unique: true, using: :btree
    end
  end
end
