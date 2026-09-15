# frozen_string_literal: true

class AddExecutionModeToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :duo_workflows_workflows, :execution_mode, :smallint
  end
end
