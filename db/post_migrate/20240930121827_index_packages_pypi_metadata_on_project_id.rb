# frozen_string_literal: true

class IndexPackagesPypiMetadataOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_pypi_metadata_on_project_id'

  def up
    add_concurrent_index :packages_pypi_metadata, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_pypi_metadata, INDEX_NAME
  end
end
