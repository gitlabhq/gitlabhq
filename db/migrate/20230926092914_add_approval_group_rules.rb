# frozen_string_literal: true

class AddApprovalGroupRules < Gitlab::Database::Migration[2.1]
  INDEX_GROUP_ID_TYPE_NAME = 'idx_on_approval_group_rules_group_id_type_name'
  INDEX_ANY_APPROVER_TYPE = 'idx_on_approval_group_rules_any_approver_type'
  INDEX_SECURITY_ORCHESTRATION_POLICY_CONFURATION = 'idx_on_approval_group_rules_security_orch_policy'
  disable_ddl_transaction!

  def up
    create_table :approval_group_rules do |t|
      t.references :group, references: :namespaces, null: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }, index: false
      t.timestamps_with_timezone
      t.integer :approvals_required, limit: 2, null: false, default: 0
      t.integer :report_type, limit: 2, null: true, default: nil
      t.integer :rule_type, limit: 2, null: false, default: 1
      t.integer :security_orchestration_policy_configuration_id, limit: 5
      t.integer :scan_result_policy_id, limit: 5, index: true
      t.text :name, null: false, limit: 255

      t.index [:group_id, :rule_type, :name], unique: true, name: INDEX_GROUP_ID_TYPE_NAME
      t.index [:group_id, :rule_type], where: 'rule_type = 4', unique: true, name: INDEX_ANY_APPROVER_TYPE
      t.index :security_orchestration_policy_configuration_id, name: INDEX_SECURITY_ORCHESTRATION_POLICY_CONFURATION
    end

    add_text_limit :approval_group_rules, :name, 255
  end

  def down
    with_lock_retries do
      drop_table :approval_group_rules
    end
  end
end
