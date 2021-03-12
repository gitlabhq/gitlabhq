# frozen_string_literal: true

class RemoveIndexForSecurityOrchestrationPolicy < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_sop_configs_on_security_policy_management_project_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:security_orchestration_policy_configurations, INDEX_NAME)
  end

  def down
    add_concurrent_index(:security_orchestration_policy_configurations, :security_policy_management_project_id, name: INDEX_NAME)
  end
end
