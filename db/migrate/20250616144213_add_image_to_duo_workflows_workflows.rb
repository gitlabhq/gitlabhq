# frozen_string_literal: true

class AddImageToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_column :duo_workflows_workflows, :image, :text
    add_text_limit :duo_workflows_workflows, :image, 2048
  end

  def down
    remove_column :duo_workflows_workflows, :image
  end
end
