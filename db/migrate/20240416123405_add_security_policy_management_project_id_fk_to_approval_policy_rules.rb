# frozen_string_literal: true

class AddSecurityPolicyManagementProjectIdFkToApprovalPolicyRules < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_policy_rules,
      :projects,
      column: :security_policy_management_project_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :approval_policy_rules, column: :security_policy_management_project_id
  end
end
