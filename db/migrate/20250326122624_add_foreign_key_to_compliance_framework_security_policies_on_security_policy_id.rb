# frozen_string_literal: true

class AddForeignKeyToComplianceFrameworkSecurityPoliciesOnSecurityPolicyId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :compliance_framework_security_policies, :security_policies,
      column: :security_policy_id,
      on_delete: :cascade,
      validate: false
  end

  def down
    remove_foreign_key_if_exists :compliance_framework_security_policies, column: :security_policy_id
  end
end
