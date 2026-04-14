# frozen_string_literal: true

class AddIndexForPipelineExecutionPolicyBotAccessGroup < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_project_settings_on_pep_bot_access_group_id'

  def up
    add_concurrent_index :project_settings, :pipeline_execution_policy_bot_access_group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_settings, INDEX_NAME
  end
end
