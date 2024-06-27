# frozen_string_literal: true

class IndexPackagesDependencyLinksOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_dependency_links_on_project_id'

  def up
    add_concurrent_index :packages_dependency_links, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_dependency_links, INDEX_NAME
  end
end
