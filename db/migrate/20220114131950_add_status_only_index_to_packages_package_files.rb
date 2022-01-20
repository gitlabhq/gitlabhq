# frozen_string_literal: true

class AddStatusOnlyIndexToPackagesPackageFiles < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_status'

  def up
    add_concurrent_index :packages_package_files, :status, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, name: INDEX_NAME
  end
end
