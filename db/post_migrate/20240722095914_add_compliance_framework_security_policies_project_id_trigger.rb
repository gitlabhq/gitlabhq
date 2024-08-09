# frozen_string_literal: true

class AddComplianceFrameworkSecurityPoliciesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :compliance_framework_security_policies,
      sharding_key: :project_id,
      parent_table: :security_orchestration_policy_configurations,
      parent_sharding_key: :project_id,
      foreign_key: :policy_configuration_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :compliance_framework_security_policies,
      sharding_key: :project_id,
      parent_table: :security_orchestration_policy_configurations,
      parent_sharding_key: :project_id,
      foreign_key: :policy_configuration_id
    )
  end
end
