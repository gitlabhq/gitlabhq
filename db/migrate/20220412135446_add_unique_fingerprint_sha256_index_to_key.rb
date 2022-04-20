# frozen_string_literal: true

class AddUniqueFingerprintSha256IndexToKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_keys_on_fingerprint_sha256'
  NEW_INDEX_NAME = 'index_keys_on_fingerprint_sha256_unique'

  def up
    add_concurrent_index :keys, :fingerprint_sha256, unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :keys, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :keys, :fingerprint_sha256, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :keys, NEW_INDEX_NAME
  end
end
