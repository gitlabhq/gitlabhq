# frozen_string_literal: true

class AddNotNullConstraintToSecurityPolicyConfigurations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    change_column_null :security_orchestration_policy_configurations, :project_id, true
  end

  def down
    exec_query 'DELETE FROM security_orchestration_policy_configurations WHERE project_id IS NULL'
    change_column_null :security_orchestration_policy_configurations, :project_id, false
  end
end
