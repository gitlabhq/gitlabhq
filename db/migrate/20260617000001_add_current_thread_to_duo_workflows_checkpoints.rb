# frozen_string_literal: true

class AddCurrentThreadToDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :p_duo_workflows_checkpoints, :current_thread, :integer, default: 0, null: false
  end
end
