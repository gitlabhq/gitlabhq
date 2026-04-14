# frozen_string_literal: true

class AddPipelineExecutionPolicyBotAccessToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :project_settings, :pipeline_execution_policy_bot_access_enabled, :boolean, default: false, null: false
    add_column :project_settings, :pipeline_execution_policy_bot_access_file_patterns, :text, array: true, default: []
    add_column :project_settings, :pipeline_execution_policy_bot_access_group_id, :bigint, null: true
  end
end
