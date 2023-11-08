# frozen_string_literal: true

class AddFrameworkFkToComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :compliance_framework_security_policies,
      :compliance_management_frameworks,
      column: :framework_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :compliance_framework_security_policies, column: :framework_id
    end
  end
end
