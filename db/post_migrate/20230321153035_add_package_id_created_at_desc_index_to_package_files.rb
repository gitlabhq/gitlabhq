# frozen_string_literal: true

class AddPackageIdCreatedAtDescIndexToPackageFiles < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_package_id_and_created_at_desc'

  def up
    add_concurrent_index :packages_package_files, 'package_id, created_at DESC', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, name: INDEX_NAME
  end
end
