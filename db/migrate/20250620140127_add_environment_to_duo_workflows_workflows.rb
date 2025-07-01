# frozen_string_literal: true

class AddEnvironmentToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :duo_workflows_workflows, :environment, :integer, limit: 2
  end
end
