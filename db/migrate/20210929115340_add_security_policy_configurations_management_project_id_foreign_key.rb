# frozen_string_literal: true

class AddSecurityPolicyConfigurationsManagementProjectIdForeignKey < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'fk_security_policy_configurations_management_project_id'
  OLD_CONSTRAINT_NAME = 'fk_rails_42ed6c25ec'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:security_orchestration_policy_configurations, :projects, column: :security_policy_management_project_id, on_delete: :cascade, name: CONSTRAINT_NAME)
    remove_foreign_key_if_exists(:security_orchestration_policy_configurations, column: :security_policy_management_project_id, on_delete: :restrict, name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(:security_orchestration_policy_configurations, :projects, column: :security_policy_management_project_id, on_delete: :restrict, name: OLD_CONSTRAINT_NAME)
    remove_foreign_key_if_exists(:security_orchestration_policy_configurations, column: :security_policy_management_project_id, on_delete: :cascade, name: CONSTRAINT_NAME)
  end
end
