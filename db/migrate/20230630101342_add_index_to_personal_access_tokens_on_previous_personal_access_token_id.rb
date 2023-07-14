# frozen_string_literal: true

class AddIndexToPersonalAccessTokensOnPreviousPersonalAccessTokenId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_personal_access_tokens_on_previous_personal_access_token_id'

  def up
    add_concurrent_index :personal_access_tokens, :previous_personal_access_token_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
