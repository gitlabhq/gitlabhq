# frozen_string_literal: true

class AddEscalationRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  RULE_SCHEDULE_INDEX_NAME = 'index_on_oncall_schedule_escalation_rule'
  UNIQUENESS_INDEX_NAME = 'index_on_policy_schedule_status_elapsed_time_escalation_rules'

  def change
    create_table :incident_management_escalation_rules do |t|
      t.belongs_to :policy, index: false, null: false, foreign_key: { on_delete: :cascade, to_table: :incident_management_escalation_policies }
      t.belongs_to :oncall_schedule, index: { name: RULE_SCHEDULE_INDEX_NAME }, null: false, foreign_key: { on_delete: :cascade, to_table: :incident_management_oncall_schedules }
      t.integer :status, null: false, limit: 2
      t.integer :elapsed_time_seconds, null: false, limit: 4

      t.index [:policy_id, :oncall_schedule_id, :status, :elapsed_time_seconds], unique: true, name: UNIQUENESS_INDEX_NAME
    end
  end
end
