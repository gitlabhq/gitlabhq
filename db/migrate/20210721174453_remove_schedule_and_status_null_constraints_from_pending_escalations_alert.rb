# frozen_string_literal: true

class RemoveScheduleAndStatusNullConstraintsFromPendingEscalationsAlert < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  # In preparation of removal of these columns in 14.3.
  def up
    with_lock_retries do
      change_column_null :incident_management_pending_alert_escalations, :status, true
      change_column_null :incident_management_pending_alert_escalations, :schedule_id, true
    end
  end

  def down
    backfill_from_rules_and_disallow_column_null :status, value: :status
    backfill_from_rules_and_disallow_column_null :schedule_id, value: :oncall_schedule_id
  end

  private

  def backfill_from_rules_and_disallow_column_null(column, value:)
    with_lock_retries do
      execute <<~SQL
        UPDATE incident_management_pending_alert_escalations AS escalations
        SET #{column} = rules.#{value}
        FROM incident_management_escalation_rules AS rules
        WHERE rule_id = rules.id
        AND escalations.#{column} IS NULL
      SQL

      change_column_null :incident_management_pending_alert_escalations, column, false
    end
  end
end
