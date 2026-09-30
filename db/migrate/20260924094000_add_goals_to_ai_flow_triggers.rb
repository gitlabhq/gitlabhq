# frozen_string_literal: true

class AddGoalsToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_flow_triggers_goals_is_hash'

  def up
    with_lock_retries do
      add_column :ai_flow_triggers, :goals, :jsonb, null: false, default: {}, if_not_exists: true
    end

    # The '{}' default satisfies the constraint, so existing rows are already valid
    # through fast defaults. Validation moves to a post-deployment migration.
    add_check_constraint(
      :ai_flow_triggers,
      "(jsonb_typeof(goals) = 'object')",
      CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_column :ai_flow_triggers, :goals, if_exists: true
    end
  end
end
