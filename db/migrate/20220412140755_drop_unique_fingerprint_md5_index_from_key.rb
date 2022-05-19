# frozen_string_literal: true

class DropUniqueFingerprintMd5IndexFromKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_keys_on_fingerprint'

  def up
    remove_concurrent_index_by_name :keys, INDEX_NAME
    add_concurrent_index :keys, :fingerprint, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :keys, INDEX_NAME
    add_concurrent_index :keys, :fingerprint, unique: true, name: INDEX_NAME
  end
end
