# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowPipelinesToProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_pipelines

  def up
    add_concurrent_foreign_key TABLE, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :project_id
    end
  end
end
