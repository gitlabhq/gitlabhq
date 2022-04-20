# frozen_string_literal: true

class DropUniqueFingerprintMd5IndexFromGroupDeployKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_group_deploy_keys_on_fingerprint'

  def up
    remove_concurrent_index_by_name :group_deploy_keys, INDEX_NAME
    add_concurrent_index :group_deploy_keys, :fingerprint, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :group_deploy_keys, INDEX_NAME
    add_concurrent_index :group_deploy_keys, :fingerprint, unique: true, name: INDEX_NAME
  end
end
