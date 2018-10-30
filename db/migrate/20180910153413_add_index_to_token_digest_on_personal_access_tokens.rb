# frozen_string_literal: true

class AddIndexToTokenDigestOnPersonalAccessTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :personal_access_tokens, :token_digest, unique: true
  end

  def down
    remove_concurrent_index :personal_access_tokens, :token_digest if index_exists?(:personal_access_tokens, :token_digest)
  end
end
