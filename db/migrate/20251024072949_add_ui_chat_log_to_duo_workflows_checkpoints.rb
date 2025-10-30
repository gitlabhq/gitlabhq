# frozen_string_literal: true

class AddUiChatLogToDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :p_duo_workflows_checkpoints, :ui_chat_log, :jsonb
  end
end
