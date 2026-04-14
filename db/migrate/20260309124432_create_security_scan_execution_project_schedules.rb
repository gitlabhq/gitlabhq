# frozen_string_literal: true

class CreateSecurityScanExecutionProjectSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  UNIQUE_INDEX_NAME = 'idx_security_sep_schedules_on_rule_schedule_id_and_project_id'
  NEXT_RUN_AT_INDEX_NAME = 'idx_security_sep_schedules_on_next_run_at_and_id'
  POLICY_PROJECT_INDEX_NAME = 'idx_security_sep_schedules_on_security_policy_id_and_project_id'

  def up
    create_table :security_scan_execution_project_schedules do |t|
      t.timestamps_with_timezone null: false
      t.references :policy_rule_schedule,
        foreign_key: { to_table: :security_orchestration_policy_rule_schedules, on_delete: :cascade },
        index: false,
        null: false
      t.references :project,
        foreign_key: { on_delete: :cascade },
        index: true,
        null: false
      t.references :security_policy,
        foreign_key: { to_table: :security_policies, on_delete: :cascade },
        index: false,
        null: false
      t.datetime_with_timezone :next_run_at, null: false
      t.integer :next_run_applied_delay, null: false, default: 0

      t.index [:policy_rule_schedule_id, :project_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index [:next_run_at, :id], name: NEXT_RUN_AT_INDEX_NAME
      t.index [:security_policy_id, :project_id], name: POLICY_PROJECT_INDEX_NAME
    end
  end

  def down
    drop_table :security_scan_execution_project_schedules
  end
end
