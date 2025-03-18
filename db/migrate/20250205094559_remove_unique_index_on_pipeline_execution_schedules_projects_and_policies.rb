# frozen_string_literal: true

class RemoveUniqueIndexOnPipelineExecutionSchedulesProjectsAndPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = :security_pipeline_execution_project_schedules
  INDEX_NAME = "uniq_idx_pipeline_execution_schedules_projects_and_policies"

  def up
    remove_index(TABLE_NAME, name: INDEX_NAME) # rubocop:disable Migration/RemoveIndex -- table was truncated
  end

  def down
    # rubocop:disable Migration/AddIndex -- table was truncated
    add_index(TABLE_NAME, %w[project_id security_policy_id], unique: true, name: INDEX_NAME)
    # rubocop:enable Migration/AddIndex
  end
end
