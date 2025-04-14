# frozen_string_literal: true

class IndexComplianceFrameworkSecurityPoliciesOnSecurityPolicyAndFramework < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  SECURITY_POLICY_INDEX_NAME = 'idx_compliance_security_policies_on_security_policy_id'
  FRAMEWORK_INDEX_NAME = 'idx_compliance_security_policies_on_framework_id'

  def up
    add_concurrent_index :compliance_framework_security_policies, :security_policy_id, name: SECURITY_POLICY_INDEX_NAME
    add_concurrent_index :compliance_framework_security_policies, :framework_id, name: FRAMEWORK_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :compliance_framework_security_policies, SECURITY_POLICY_INDEX_NAME
    remove_concurrent_index_by_name :compliance_framework_security_policies, FRAMEWORK_INDEX_NAME
  end
end
