# frozen_string_literal: true

class AddSummaryToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_column :duo_workflows_workflows, :summary, :text, null: true, if_not_exist: true
    add_text_limit :duo_workflows_workflows, :summary, 1_024
  end

  def down
    remove_column :duo_workflows_workflows, :summary, if_exists: true
  end
end
