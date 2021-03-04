# frozen_string_literal: true

class AddIndexToSecurityOrchestrationPolicy < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX = 'index_sop_configurations_project_id_policy_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_orchestration_policy_configurations, [:security_policy_management_project_id, :project_id], name: INDEX
  end

  def down
    remove_concurrent_index_by_name :security_orchestration_policy_configurations, INDEX
  end
end
