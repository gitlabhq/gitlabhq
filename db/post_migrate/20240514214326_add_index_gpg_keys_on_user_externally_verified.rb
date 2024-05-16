# frozen_string_literal: true

class AddIndexGpgKeysOnUserExternallyVerified < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_gpg_keys_on_user_externally_verified'

  disable_ddl_transaction!
  milestone '17.1'

  def up
    add_concurrent_index :gpg_keys, :user_id, name: INDEX_NAME, where: 'externally_verified = true'
  end

  def down
    remove_concurrent_index_by_name :gpg_keys, INDEX_NAME
  end
end
