# frozen_string_literal: true

class AddShardingKeyIndexesToDeployTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  PROJECT_ID_INDEX = 'index_deploy_tokens_on_project_id'
  GROUP_ID_INDEX = 'index_deploy_tokens_on_group_id'

  def up
    add_concurrent_index :deploy_tokens, :project_id, name: PROJECT_ID_INDEX
    add_concurrent_index :deploy_tokens, :group_id, name: GROUP_ID_INDEX
  end

  def down
    remove_concurrent_index_by_name :deploy_tokens, GROUP_ID_INDEX
    remove_concurrent_index_by_name :deploy_tokens, PROJECT_ID_INDEX
  end
end
