# frozen_string_literal: true

class UpdateIndexPackagesPackageFilesOnPackageIdAndFileName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = :packages_package_files
  NEW_INDEX = :index_packages_package_files_on_package_id_file_name_file_sha1
  OLD_INDEX = :index_packages_package_files_on_package_id_and_file_name

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Replacing existing index
    add_concurrent_index(TABLE_NAME, %i[package_id file_name file_sha1], name: NEW_INDEX)
    # rubocop:enable Migration/PreventIndexCreation
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX)
  end

  def down
    add_concurrent_index(TABLE_NAME, %i[package_id file_name], name: OLD_INDEX)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX)
  end
end
