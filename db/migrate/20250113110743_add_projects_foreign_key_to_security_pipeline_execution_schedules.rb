# frozen_string_literal: true

class AddProjectsForeignKeyToSecurityPipelineExecutionSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :security_pipeline_execution_project_schedules,
      :projects,
      column: :project_id,
      on_delete: :cascade
    )
  end

  def down
    remove_foreign_key_if_exists :security_pipeline_execution_project_schedules, column: :project_id
  end
end
