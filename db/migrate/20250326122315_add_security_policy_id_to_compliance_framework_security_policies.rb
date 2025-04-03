# frozen_string_literal: true

class AddSecurityPolicyIdToComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :compliance_framework_security_policies, :security_policy_id, :bigint
  end
end
