# frozen_string_literal: true

class RemoveNullConstraintOnScheduleFromEscalationRules < ActiveRecord::Migration[6.1]
  def up
    change_column_null :incident_management_escalation_rules, :oncall_schedule_id, true
  end

  def down
    exec_query 'DELETE FROM incident_management_escalation_rules WHERE oncall_schedule_id IS NULL'

    change_column_null :incident_management_escalation_rules, :oncall_schedule_id, false
  end
end
