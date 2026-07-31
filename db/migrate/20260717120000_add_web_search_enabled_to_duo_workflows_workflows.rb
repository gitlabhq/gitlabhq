# frozen_string_literal: true

class AddWebSearchEnabledToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :duo_workflows_workflows, :web_search_enabled, :boolean, default: false, null: false
  end
end
