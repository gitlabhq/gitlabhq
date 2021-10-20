# frozen_string_literal: true

class AddStatusIndexToDependencyProxyTables < Gitlab::Database::Migration[1.0]
  MANIFEST_INDEX_NAME = 'index_dependency_proxy_manifests_on_status'
  BLOB_INDEX_NAME = 'index_dependency_proxy_blobs_on_status'

  disable_ddl_transaction!

  def up
    add_concurrent_index :dependency_proxy_manifests, :status, name: MANIFEST_INDEX_NAME
    add_concurrent_index :dependency_proxy_blobs, :status, name: BLOB_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_proxy_manifests, MANIFEST_INDEX_NAME
    remove_concurrent_index_by_name :dependency_proxy_blobs, BLOB_INDEX_NAME
  end
end
