# frozen_string_literal: true

class ChangeIndexPackagesNpmMetadataCachesOnProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  NEW_INDEX_NAME = :index_packages_npm_metadata_caches_on_project_id_status
  OLD_INDEX_NAME = :index_packages_npm_metadata_caches_on_project_id

  def up
    add_concurrent_index :packages_npm_metadata_caches, [:project_id, :status], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :packages_npm_metadata_caches, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :packages_npm_metadata_caches, :project_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :packages_npm_metadata_caches, NEW_INDEX_NAME
  end
end
