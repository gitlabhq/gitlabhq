# frozen_string_literal: true

class AddPackageIdFileExtensionStatusIndexToPackageFiles < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_package_file_extension_status'
  STATUS_INSTALLABLE = 0
  EXT = 'nupkg'
  INDEX_WHERE = "((status = #{STATUS_INSTALLABLE}) AND (reverse(split_part(reverse(file_name), '.', 1)) = '#{EXT}'))"

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :packages_package_files, :package_id, where: INDEX_WHERE, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, name: INDEX_NAME
  end
end
