# frozen_string_literal: true

class AddIndexOnPersonalAccessTokensUserIdAndExpiresAt < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_pat_on_user_id_and_expires_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :personal_access_tokens, [:user_id, :expires_at], name: INDEX_NAME, using: :btree
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
