# frozen_string_literal: true

class AddUniqueFingerprintSha256IndexToGroupDeployKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_group_deploy_keys_on_fingerprint_sha256'
  NEW_INDEX_NAME = 'index_group_deploy_keys_on_fingerprint_sha256_unique'

  def up
    add_concurrent_index :group_deploy_keys, :fingerprint_sha256, unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :group_deploy_keys, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :group_deploy_keys, :fingerprint_sha256, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :group_deploy_keys, NEW_INDEX_NAME
  end
end
