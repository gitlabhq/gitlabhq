# frozen_string_literal: true

class AddPolicyConfigurationFkToComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :compliance_framework_security_policies,
      :security_orchestration_policy_configurations,
      column: :policy_configuration_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :compliance_framework_security_policies, column: :policy_configuration_id
    end
  end
end
