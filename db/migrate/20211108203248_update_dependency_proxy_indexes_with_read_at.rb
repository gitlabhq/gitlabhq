# frozen_string_literal: true

class UpdateDependencyProxyIndexesWithReadAt < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  NEW_BLOB_INDEX = 'index_dependency_proxy_blobs_on_group_id_status_read_at_id'
  OLD_BLOB_INDEX = 'index_dependency_proxy_blobs_on_group_id_status_and_id'

  NEW_MANIFEST_INDEX = 'index_dependency_proxy_manifests_on_group_id_status_read_at_id'
  OLD_MANIFEST_INDEX = 'index_dependency_proxy_manifests_on_group_id_status_and_id'

  def up
    add_concurrent_index :dependency_proxy_blobs, [:group_id, :status, :read_at, :id], name: NEW_BLOB_INDEX
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :status, :read_at, :id], name: NEW_MANIFEST_INDEX

    remove_concurrent_index_by_name :dependency_proxy_blobs, OLD_BLOB_INDEX
    remove_concurrent_index_by_name :dependency_proxy_manifests, OLD_MANIFEST_INDEX
  end

  def down
    add_concurrent_index :dependency_proxy_blobs, [:group_id, :status, :id], name: OLD_BLOB_INDEX
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :status, :id], name: OLD_MANIFEST_INDEX

    remove_concurrent_index_by_name :dependency_proxy_blobs, NEW_BLOB_INDEX
    remove_concurrent_index_by_name :dependency_proxy_manifests, NEW_MANIFEST_INDEX
  end
end
