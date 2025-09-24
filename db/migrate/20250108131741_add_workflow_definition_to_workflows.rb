# frozen_string_literal: true

class AddWorkflowDefinitionToWorkflows < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  def up
    with_lock_retries do
      add_column :duo_workflows_workflows, :workflow_definition, :text, default: 'software_development',
        null: false
    end

    add_text_limit :duo_workflows_workflows, :workflow_definition, 255
  end

  def down
    with_lock_retries do
      remove_column :duo_workflows_workflows, :workflow_definition
    end
  end
end
