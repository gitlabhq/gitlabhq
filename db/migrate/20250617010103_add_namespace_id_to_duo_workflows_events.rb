# frozen_string_literal: true

class AddNamespaceIdToDuoWorkflowsEvents < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :duo_workflows_events, :namespace_id, :bigint
  end
end
