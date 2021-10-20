# frozen_string_literal: true

class UpdateDependencyProxyManifestsUniquenessConstraint < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_dep_prox_manifests_on_group_id_file_name_and_status'
  OLD_INDEX_NAME = 'index_dependency_proxy_manifests_on_group_id_and_file_name'

  def up
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :file_name, :status], unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :dependency_proxy_manifests, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :file_name], unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :dependency_proxy_manifests, NEW_INDEX_NAME
  end
end
