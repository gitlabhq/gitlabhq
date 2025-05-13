# frozen_string_literal: true

class IndexComplianceSecurityPoliciesOnSecurityPolicyAndId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_compliance_security_policies_on_security_policy_and_id'

  def up
    add_concurrent_index :compliance_framework_security_policies, [:security_policy_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :compliance_framework_security_policies, INDEX_NAME
  end
end
