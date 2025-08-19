# frozen_string_literal: true

class AddIndexTokenEncrypted < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_triggers_on_token_encrypted'

  def up
    add_concurrent_index :ci_triggers, :token_encrypted, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index :ci_triggers, :token_encrypted, name: INDEX_NAME
  end
end
