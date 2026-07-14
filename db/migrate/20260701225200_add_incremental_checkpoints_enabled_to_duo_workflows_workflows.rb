# frozen_string_literal: true

class AddIncrementalCheckpointsEnabledToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :duo_workflows_workflows, :incremental_checkpoints_enabled, :boolean, default: false, null: false
  end
end
