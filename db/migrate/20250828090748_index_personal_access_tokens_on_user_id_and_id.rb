# frozen_string_literal: true

class IndexPersonalAccessTokensOnUserIdAndId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  INDEX_NAME = 'index_personal_access_tokens_on_user_id_and_id'
  INDEX_NAME_TO_REMOVE = 'index_personal_access_tokens_on_user_id'

  def up
    add_concurrent_index :personal_access_tokens, [:user_id, :id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- We need this index to optimize the application code. We can remove existing index_personal_access_tokens_on_user_id.

    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME_TO_REMOVE
  end

  def down
    add_concurrent_index :personal_access_tokens, [:user_id], name: INDEX_NAME_TO_REMOVE

    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
