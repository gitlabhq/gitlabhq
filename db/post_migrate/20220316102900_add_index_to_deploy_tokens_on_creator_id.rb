# frozen_string_literal: true

class AddIndexToDeployTokensOnCreatorId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_deploy_tokens_on_creator_id'

  def up
    add_concurrent_index :deploy_tokens, :creator_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :deploy_tokens, :creator_id, name: INDEX_NAME
  end
end
