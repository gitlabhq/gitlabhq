# frozen_string_literal: true

class ChangeIndexOnGpgKeyIdOfGpgSignatures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_gpg_signatures_on_gpg_key_id_and_id'
  OLD_INDEX_NAME = 'index_gpg_signatures_on_gpg_key_id'

  def up
    add_concurrent_index :gpg_signatures, [:gpg_key_id, :id], name: INDEX_NAME
    remove_concurrent_index_by_name :gpg_signatures, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :gpg_signatures, :gpg_key_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :gpg_signatures, name: INDEX_NAME
  end
end
