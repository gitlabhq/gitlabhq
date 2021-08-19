# frozen_string_literal: true

class AddNonNullConstraintForEscalationRuleOnPendingAlertEscalations < ActiveRecord::Migration[6.1]
  ELAPSED_WHOLE_MINUTES_IN_SECONDS = <<~SQL
    ABS(ROUND(
      EXTRACT(EPOCH FROM (escalations.process_at - escalations.created_at))/60*60
    ))
  SQL

  INSERT_RULES_FOR_ESCALATIONS_WITHOUT_RULES = <<~SQL
    INSERT INTO incident_management_escalation_rules (policy_id, oncall_schedule_id, status, elapsed_time_seconds, is_removed)
    SELECT
      policies.id,
      schedule_id,
      status,
      #{ELAPSED_WHOLE_MINUTES_IN_SECONDS} AS elapsed_time_seconds,
      TRUE
    FROM incident_management_pending_alert_escalations AS escalations
    INNER JOIN incident_management_oncall_schedules AS schedules ON schedules.id = schedule_id
    INNER JOIN incident_management_escalation_policies AS policies ON policies.project_id = schedules.project_id
    WHERE rule_id IS NULL
    GROUP BY policies.id, schedule_id, status, elapsed_time_seconds
    ON CONFLICT DO NOTHING;
  SQL

  UPDATE_EMPTY_RULE_IDS = <<~SQL
    UPDATE incident_management_pending_alert_escalations AS escalations
    SET rule_id = rules.id
    FROM incident_management_pending_alert_escalations AS through_escalations
    INNER JOIN incident_management_oncall_schedules AS schedules ON schedules.id = through_escalations.schedule_id
    INNER JOIN incident_management_escalation_policies AS policies ON policies.project_id = schedules.project_id
    INNER JOIN incident_management_escalation_rules AS rules ON rules.policy_id = policies.id
    WHERE escalations.rule_id IS NULL
    AND rules.status = escalations.status
    AND rules.oncall_schedule_id = escalations.schedule_id
    AND rules.elapsed_time_seconds = #{ELAPSED_WHOLE_MINUTES_IN_SECONDS};
  SQL

  DELETE_LEFTOVER_ESCALATIONS_WITHOUT_RULES = 'DELETE FROM incident_management_pending_alert_escalations WHERE rule_id IS NULL;'

  # For each alert which has a pending escalation without a corresponding rule,
  # create a rule with the expected attributes for the project's policy.
  #
  # Deletes all escalations without rules/policy & adds non-null constraint for rule_id.
  def up
    exec_query INSERT_RULES_FOR_ESCALATIONS_WITHOUT_RULES
    exec_query UPDATE_EMPTY_RULE_IDS
    exec_query DELETE_LEFTOVER_ESCALATIONS_WITHOUT_RULES

    change_column_null :incident_management_pending_alert_escalations, :rule_id, false
  end

  def down
    change_column_null :incident_management_pending_alert_escalations, :rule_id, true
  end
end
