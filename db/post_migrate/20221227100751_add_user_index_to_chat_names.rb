# frozen_string_literal: true

class AddUserIndexToChatNames < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_names_on_user_id'

  def up
    add_concurrent_index(:chat_names, :user_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:chat_names, name: INDEX_NAME)
  end
end
