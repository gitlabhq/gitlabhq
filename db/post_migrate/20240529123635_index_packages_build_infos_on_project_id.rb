# frozen_string_literal: true

class IndexPackagesBuildInfosOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_build_infos_on_project_id'

  def up
    add_concurrent_index :packages_build_infos, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_build_infos, INDEX_NAME
  end
end
