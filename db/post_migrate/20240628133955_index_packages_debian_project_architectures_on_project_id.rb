# frozen_string_literal: true

class IndexPackagesDebianProjectArchitecturesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_debian_project_architectures_on_project_id'

  def up
    add_concurrent_index :packages_debian_project_architectures, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_debian_project_architectures, INDEX_NAME
  end
end
