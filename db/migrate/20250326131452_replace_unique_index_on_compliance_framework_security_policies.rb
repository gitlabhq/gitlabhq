# frozen_string_literal: true

class ReplaceUniqueIndexOnComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  INDEX_TO_REMOVE = "unique_compliance_framework_security_policies_framework_id"
  UNIQUE_INDEX_ON_SECURITY_POLICY = "unique_compliance_security_policies_security_policy_id"
  UNIQUE_INDEX_ON_POLICY_INDEX = "unique_compliance_security_policies_framework_id_policy_index"

  disable_ddl_transaction!

  milestone '17.11'

  def up
    add_concurrent_index :compliance_framework_security_policies,
      [:security_policy_id, :framework_id],
      unique: true,
      where: 'security_policy_id IS NOT NULL',
      name: UNIQUE_INDEX_ON_SECURITY_POLICY

    add_concurrent_index :compliance_framework_security_policies,
      [:framework_id, :policy_configuration_id, :policy_index],
      unique: true,
      where: 'security_policy_id IS NULL',
      name: UNIQUE_INDEX_ON_POLICY_INDEX
    remove_concurrent_index_by_name :compliance_framework_security_policies, name: INDEX_TO_REMOVE
  end

  def down
    add_concurrent_index :compliance_framework_security_policies,
      [:framework_id, :policy_configuration_id, :policy_index],
      unique: true,
      name: INDEX_TO_REMOVE
    remove_concurrent_index_by_name :compliance_framework_security_policies, name: UNIQUE_INDEX_ON_SECURITY_POLICY
    remove_concurrent_index_by_name :compliance_framework_security_policies, name: UNIQUE_INDEX_ON_POLICY_INDEX
  end
end
