# frozen_string_literal: true

class AddApprovalPolicyRulesFkOnSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_software_license_policies_on_approval_policy_rule_id'

  def up
    add_concurrent_index :software_license_policies, :approval_policy_rule_id, name: INDEX_NAME
    add_concurrent_foreign_key :software_license_policies, :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :software_license_policies, column: :approval_policy_rule_id
    remove_concurrent_index_by_name :software_license_policies, INDEX_NAME
  end
end
