# frozen_string_literal: true

class AddTextLimitToDuoWorkflowsGoal < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  def up
    add_text_limit :duo_workflows_workflows, :goal, 4096
  end

  def down
    remove_text_limit :duo_workflows_workflows, :goal
  end
end
