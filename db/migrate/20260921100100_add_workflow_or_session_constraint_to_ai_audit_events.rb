# frozen_string_literal: true

class AddWorkflowOrSessionConstraintToAiAuditEvents < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_audit_event_has_workflow_or_session'

  # Added NOT VALID here and validated in a post-deployment migration, because unlike
  # ai_governance_sessions the table already holds production rows.
  def up
    add_multi_column_not_null_constraint(
      :ai_audit_events,
      :workflow_id,
      :ai_governance_session_id,
      operator: '>=',
      constraint_name: CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :ai_audit_events,
      :workflow_id,
      :ai_governance_session_id,
      constraint_name: CONSTRAINT_NAME
    )
  end
end
