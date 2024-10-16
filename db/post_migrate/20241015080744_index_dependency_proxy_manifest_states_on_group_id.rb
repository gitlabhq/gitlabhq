# frozen_string_literal: true

class IndexDependencyProxyManifestStatesOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dependency_proxy_manifest_states_on_group_id'

  def up
    add_concurrent_index :dependency_proxy_manifest_states, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_proxy_manifest_states, INDEX_NAME
  end
end
