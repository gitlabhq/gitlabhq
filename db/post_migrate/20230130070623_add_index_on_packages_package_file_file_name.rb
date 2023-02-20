# frozen_string_literal: true

class AddIndexOnPackagesPackageFileFileName < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_packages_package_files_on_file_name'

  def up
    prepare_async_index :packages_package_files, :file_name, name: INDEX_NAME, using: :gin,
                         opclass: { description: :gin_trgm_ops }
  end

  def down
    unprepare_async_index :packages_package_files, :file_name, name: INDEX_NAME
  end
end
