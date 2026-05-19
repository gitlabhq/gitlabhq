# frozen_string_literal: true

class AddMessagingCallbackContextToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :duo_workflows_workflows, :messaging_callback_context, :jsonb, null: true, if_not_exists: true
  end
end
