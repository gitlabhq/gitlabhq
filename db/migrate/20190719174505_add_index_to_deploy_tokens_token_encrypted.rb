# frozen_string_literal: true

class AddIndexToDeployTokensTokenEncrypted < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deploy_tokens, :token_encrypted, unique: true, name: "index_deploy_tokens_on_token_encrypted"
  end

  def down
    remove_concurrent_index_by_name :deploy_tokens, "index_deploy_tokens_on_token_encrypted"
  end
end
