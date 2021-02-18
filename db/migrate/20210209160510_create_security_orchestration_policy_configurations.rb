# frozen_string_literal: true

class CreateSecurityOrchestrationPolicyConfigurations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_PREFIX = 'index_sop_configs_'

  def up
    table_comment = { owner: 'group::container security', description: 'Configuration used to store relationship between project and security policy repository' }

    create_table_with_constraints :security_orchestration_policy_configurations, comment: table_comment.to_json do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }, index: { name: INDEX_PREFIX + 'on_project_id', unique: true }
      t.references :security_policy_management_project, null: false, foreign_key: { to_table: :projects, on_delete: :restrict }, index: { name: INDEX_PREFIX + 'on_security_policy_management_project_id', unique: true }

      t.timestamps_with_timezone
    end
  end

  def down
    with_lock_retries do
      drop_table :security_orchestration_policy_configurations, force: :cascade
    end
  end
end
