# frozen_string_literal: true

class AddIndexOnPackagesIdIdToPackageBuildInfos < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_build_infos_package_id_id'

  def up
    add_concurrent_index :packages_build_infos, [:package_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_build_infos, name: INDEX_NAME
  end
end
