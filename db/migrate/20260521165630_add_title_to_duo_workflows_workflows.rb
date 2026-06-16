# frozen_string_literal: true

class AddTitleToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :duo_workflows_workflows, :title, :text, null: true, if_not_exists: true
    add_text_limit :duo_workflows_workflows, :title, 40
  end

  def down
    remove_column :duo_workflows_workflows, :title, if_exists: true
  end
end
