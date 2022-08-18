# frozen_string_literal: true

class IndexPersonalAccessTokensOnIdAndCreatedAt < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_personal_access_tokens_on_id_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :personal_access_tokens, [:id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
