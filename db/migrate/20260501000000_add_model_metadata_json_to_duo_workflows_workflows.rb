# frozen_string_literal: true

class AddModelMetadataJsonToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_column :duo_workflows_workflows, :model_metadata_json, :text, null: true, if_not_exists: true
    add_text_limit :duo_workflows_workflows, :model_metadata_json, 1_024
  end

  def down
    remove_column :duo_workflows_workflows, :model_metadata_json, if_exists: true
  end
end
