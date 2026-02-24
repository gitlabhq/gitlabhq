# frozen_string_literal: true

class AddFilterToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_flow_triggers_filter_is_hash'

  def up
    with_lock_retries do
      add_column :ai_flow_triggers, :filter, :jsonb, null: false, default: {}, if_not_exists: true
    end

    add_check_constraint(
      :ai_flow_triggers,
      "(jsonb_typeof(filter) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    with_lock_retries do
      remove_column :ai_flow_triggers, :filter, if_exists: true
    end
  end
end
