# frozen_string_literal: true

class CreateSecurityOrchestrationPolicyRuleSchedule < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_PREFIX = 'index_sop_schedules_'

  disable_ddl_transaction!

  def up
    table_comment = { owner: 'group::container security', description: 'Schedules used to store relationship between project and security policy repository' }

    create_table_with_constraints :security_orchestration_policy_rule_schedules, comment: table_comment.to_json do |t|
      t.timestamps_with_timezone
      t.datetime_with_timezone :next_run_at, null: true

      t.references :security_orchestration_policy_configuration, null: false, foreign_key: { to_table: :security_orchestration_policy_configurations, on_delete: :cascade }, index: { name: INDEX_PREFIX + 'on_sop_configuration_id' }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { name: INDEX_PREFIX + 'on_user_id' }

      t.integer :policy_index, null: false
      t.text :cron, null: false

      t.text_limit :cron, 255
    end
  end

  def down
    with_lock_retries do
      drop_table :security_orchestration_policy_rule_schedules
    end
  end
end
