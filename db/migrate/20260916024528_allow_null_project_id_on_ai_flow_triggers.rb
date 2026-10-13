# frozen_string_literal: true

class AllowNullProjectIdOnAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    change_column_null :ai_flow_triggers, :project_id, true
  end

  def down
    # Group-scoped triggers have project_id NULL by design, so restoring
    # NOT NULL would fail or require deleting legitimate data.
    change_column_null :ai_flow_triggers, :project_id, false
  end
end
