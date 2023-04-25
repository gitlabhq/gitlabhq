# frozen_string_literal: true

class FixUniquePackagesIndexExcludingPendingDestructionStatus < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  GO_UNIQUE_INDEX_NAME = 'index_packages_on_project_id_name_version_unique_when_golang'
  GENERIC_UNIQUE_INDEX_NAME = 'index_packages_on_project_id_name_version_unique_when_generic'
  HELM_UNIQUE_INDEX_NAME = 'index_packages_on_project_id_name_version_unique_when_helm'

  NEW_GO_UNIQUE_INDEX_NAME = 'idx_packages_on_project_id_name_version_unique_when_golang'
  NEW_GENERIC_UNIQUE_INDEX_NAME = 'idx_packages_on_project_id_name_version_unique_when_generic'
  NEW_HELM_UNIQUE_INDEX_NAME = 'idx_packages_on_project_id_name_version_unique_when_helm'

  def up
    add_concurrent_index :packages_packages, [:project_id, :name, :version], unique: true, name: NEW_GO_UNIQUE_INDEX_NAME, where: 'package_type = 8 AND status != 4'
    add_concurrent_index :packages_packages, [:project_id, :name, :version], unique: true, name: NEW_GENERIC_UNIQUE_INDEX_NAME, where: 'package_type = 7 AND status != 4'
    add_concurrent_index :packages_packages, [:project_id, :name, :version], unique: true, name: NEW_HELM_UNIQUE_INDEX_NAME, where: 'package_type = 11 AND status != 4'

    remove_concurrent_index_by_name :packages_packages, GO_UNIQUE_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, GENERIC_UNIQUE_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, HELM_UNIQUE_INDEX_NAME
  end

  def down
    # no-op
    # We can't guarantee that the old index can be recreated since it targets a set larger that the new index.
  end
end
