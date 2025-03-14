# frozen_string_literal: true

class IndexPackagesNugetDependencyLinkMetadataOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_nuget_dependency_link_metadata_on_project_id'

  def up
    add_concurrent_index :packages_nuget_dependency_link_metadata, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_nuget_dependency_link_metadata, INDEX_NAME
  end
end
