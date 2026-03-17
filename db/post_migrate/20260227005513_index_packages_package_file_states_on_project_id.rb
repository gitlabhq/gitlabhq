# frozen_string_literal: true

class IndexPackagesPackageFileStatesOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_file_states_on_project_id'

  def up
    add_concurrent_index :packages_package_file_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_file_states, INDEX_NAME
  end
end
