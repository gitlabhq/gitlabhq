# frozen_string_literal: true

class RemoveIndexUsersWithStaticObjectToken < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_users_with_static_object_token
  TABLE_NAME = :users
  WHERE_STATEMENT = 'static_object_token IS NOT NULL AND static_object_token_encrypted IS NULL'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :id, where: WHERE_STATEMENT, name: INDEX_NAME
  end
end
