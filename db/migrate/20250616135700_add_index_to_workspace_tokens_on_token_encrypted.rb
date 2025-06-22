# frozen_string_literal: true

class AddIndexToWorkspaceTokensOnTokenEncrypted < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  TABLE_NAME = :workspace_tokens
  INDEX_NAME = "index_workspace_tokens_on_token_encrypted"

  def up
    add_concurrent_index TABLE_NAME, :token_encrypted, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
