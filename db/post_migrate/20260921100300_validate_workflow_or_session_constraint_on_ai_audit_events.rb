# frozen_string_literal: true

class ValidateWorkflowOrSessionConstraintOnAiAuditEvents < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_audit_event_has_workflow_or_session'

  def up
    validate_check_constraint :ai_audit_events, CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
