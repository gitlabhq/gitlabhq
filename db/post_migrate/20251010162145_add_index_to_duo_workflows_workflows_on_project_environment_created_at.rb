# frozen_string_literal: true

class AddIndexToDuoWorkflowsWorkflowsOnProjectEnvironmentCreatedAt < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = "index_duo_workflows_workflows_project_environment_created_at"

  def up
    add_concurrent_index(
      :duo_workflows_workflows,
      [:project_id, :environment, :created_at],
      order: { created_at: :DESC },
      where: "workflow_definition != 'chat'",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :duo_workflows_workflows,
      INDEX_NAME
    )
  end
end
