# frozen_string_literal: true

class RemoveNotNullConstraintFromDuoWorkflowsCheckpointsProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.2'

  def up
    change_column_null :duo_workflows_checkpoints, :project_id, true
  end

  def down
    change_column_null :duo_workflows_checkpoints, :project_id, false
  end
end
