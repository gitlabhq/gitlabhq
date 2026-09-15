# frozen_string_literal: true

class AddTriggerEventTypeToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    # No default: EVENT_TYPES[:mention] is 0, so default: 0 would silently
    # label every untriggered session a mention.
    add_column :duo_workflows_workflows, :trigger_event_type, :integer, limit: 2, null: true
  end
end
