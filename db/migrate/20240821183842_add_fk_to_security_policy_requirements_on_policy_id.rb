# frozen_string_literal: true

class AddFkToSecurityPolicyRequirementsOnPolicyId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :security_policy_requirements, :compliance_framework_security_policies,
      column: :compliance_framework_security_policy_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :security_policy_requirements, column: :compliance_framework_security_policy_id,
        reverse_lock_order: true
    end
  end
end
