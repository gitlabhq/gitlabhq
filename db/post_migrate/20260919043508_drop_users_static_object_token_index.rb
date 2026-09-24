# frozen_string_literal: true

class DropUsersStaticObjectTokenIndex < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :users
  INDEX_NAME = :index_users_on_static_object_token

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :static_object_token, unique: true, name: INDEX_NAME
  end
end
