# frozen_string_literal: true

class AddTemporaryStaticObjectTokenIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_users_with_static_object_token'

  def up
    add_concurrent_index :users, :id, where: "static_object_token IS NOT NULL AND static_object_token_encrypted IS NULL", name: INDEX_NAME
  end

  def down
    remove_concurrent_index :users, :id, name: INDEX_NAME
  end
end
