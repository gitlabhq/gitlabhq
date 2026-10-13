# frozen_string_literal: true

class ValidateAiFlowTriggersGoalsIsHash < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_flow_triggers_goals_is_hash'

  def up
    validate_check_constraint :ai_flow_triggers, CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
