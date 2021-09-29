# frozen_string_literal: true

class AddGroupIdStatusIdIndexToDependencyProxyTables < Gitlab::Database::Migration[1.0]
  MANIFEST_INDEX_NAME = 'index_dependency_proxy_manifests_on_group_id_status_and_id'
  BLOB_INDEX_NAME = 'index_dependency_proxy_blobs_on_group_id_status_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :status, :id], name: MANIFEST_INDEX_NAME
    add_concurrent_index :dependency_proxy_blobs, [:group_id, :status, :id], name: BLOB_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_proxy_manifests, MANIFEST_INDEX_NAME
    remove_concurrent_index_by_name :dependency_proxy_blobs, BLOB_INDEX_NAME
  end
end
