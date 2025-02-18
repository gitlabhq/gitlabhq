# frozen_string_literal: true

class CreateMergeRequestsApprovalRules < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :merge_requests_approval_rules do |t| # -- Migration/EnsureFactoryForTable false positive
      t.text :name, limit: 255, null: false
      t.integer :approvals_required, null: false, default: 0
      t.integer :rule_type, null: false, default: 0, limit: 2
      t.integer :origin, null: false, default: 0, limit: 2
      t.bigint :project_id, null: true
      t.bigint :group_id, null: true
      t.bigint :source_rule_id, null: true
      t.index :project_id
      t.index :group_id
      t.index :source_rule_id
      t.timestamps_with_timezone null: false
    end
  end
end
