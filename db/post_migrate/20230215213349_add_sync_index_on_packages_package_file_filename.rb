# frozen_string_literal: true

class AddSyncIndexOnPackagesPackageFileFilename < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_packages_package_files_on_file_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :packages_package_files,
      :file_name,
      name: INDEX_NAME,
      using: :gin,
      opclass: { description: :gin_trgm_ops }
    )
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end
