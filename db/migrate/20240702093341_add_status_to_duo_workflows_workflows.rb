# frozen_string_literal: true

class AddStatusToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :duo_workflows_workflows, :status, :smallint, default: 0, null: false
  end
end
