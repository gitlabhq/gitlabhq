# frozen_string_literal: true

class AddIndexOnPackagesBuildInfosPackageIdPipelineId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_build_infos_package_id_pipeline_id'
  OLD_INDEX_NAME = 'idx_packages_build_infos_on_package_id'

  def up
    add_concurrent_index :packages_build_infos, [:package_id, :pipeline_id], name: INDEX_NAME
    remove_concurrent_index_by_name :packages_build_infos, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :packages_build_infos, :package_id, name: OLD_INDEX_NAME
    remove_concurrent_index :packages_build_infos, [:package_id, :pipeline_id], name: INDEX_NAME
  end
end
