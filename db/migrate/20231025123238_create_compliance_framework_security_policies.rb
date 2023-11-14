# frozen_string_literal: true

class CreateComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  UNIQUE_INDEX_NAME = 'unique_compliance_framework_security_policies_framework_id'
  POLICY_CONFIGURATION_INDEX_NAME = 'idx_compliance_security_policies_on_policy_configuration_id'

  milestone '16.6'
  enable_lock_retries!

  def change
    create_table :compliance_framework_security_policies do |t|
      t.bigint :framework_id, null: false
      t.bigint :policy_configuration_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :policy_index, limit: 2, null: false

      t.index :policy_configuration_id, name: POLICY_CONFIGURATION_INDEX_NAME
      t.index [:framework_id, :policy_configuration_id, :policy_index], unique: true, name: UNIQUE_INDEX_NAME
    end
  end
end
