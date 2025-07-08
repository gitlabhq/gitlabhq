# frozen_string_literal: true

class AddProjectOrNamespaceConstraintToDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.2'

  def up
    add_multi_column_not_null_constraint(:duo_workflows_checkpoints, :project_id, :namespace_id)
  end

  def down
    remove_multi_column_not_null_constraint(:duo_workflows_checkpoints, :project_id, :namespace_id)
  end
end
