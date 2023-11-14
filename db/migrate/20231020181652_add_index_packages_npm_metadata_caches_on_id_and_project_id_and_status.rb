# frozen_string_literal: true

class AddIndexPackagesNpmMetadataCachesOnIdAndProjectIdAndStatus < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_pkgs_npm_metadata_caches_on_id_and_project_id_and_status'
  NPM_METADATA_CACHES_STATUS_DEFAULT = 0

  def up
    where = "project_id IS NULL AND status = #{NPM_METADATA_CACHES_STATUS_DEFAULT}"

    add_concurrent_index :packages_npm_metadata_caches, :id, name: INDEX_NAME, where: where
  end

  def down
    remove_concurrent_index_by_name :packages_npm_metadata_caches, name: INDEX_NAME
  end
end
