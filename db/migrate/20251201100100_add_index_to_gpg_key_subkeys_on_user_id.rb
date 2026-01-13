# frozen_string_literal: true

class AddIndexToGpgKeySubkeysOnUserId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_gpg_key_subkeys_on_user_id'

  milestone '18.8'
  disable_ddl_transaction!

  def up
    add_concurrent_index :gpg_key_subkeys, :user_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :gpg_key_subkeys, INDEX_NAME
  end
end
