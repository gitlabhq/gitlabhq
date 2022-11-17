# frozen_string_literal: true

class AddIndexOnPasswordLastChangedAtToUserDetails < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_user_details_on_password_last_changed_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_details, :password_last_changed_at, name: INDEX_NAME, comment: 'JiHu-specific index'
  end

  def down
    remove_concurrent_index_by_name :user_details, INDEX_NAME
  end
end
