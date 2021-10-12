# frozen_string_literal: true

class AddUniqueIndexPhoneOnUserDetails < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_details_on_phone'

  def up
    add_concurrent_index :user_details, :phone, unique: true, where: 'phone IS NOT NULL', name: INDEX_NAME, comment: 'JiHu-specific index'
  end

  def down
    remove_concurrent_index_by_name :user_details, INDEX_NAME
  end
end
