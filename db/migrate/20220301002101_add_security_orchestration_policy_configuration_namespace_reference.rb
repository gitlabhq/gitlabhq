# frozen_string_literal: true

class AddSecurityOrchestrationPolicyConfigurationNamespaceReference < Gitlab::Database::Migration[1.0]
  def up
    add_column :security_orchestration_policy_configurations, :namespace_id, :bigint
  end

  def down
    remove_column :security_orchestration_policy_configurations, :namespace_id
  end
end
