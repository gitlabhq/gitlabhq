# frozen_string_literal: true

class AddStatusIndexToPackagesPackageFiles < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_package_id_status_and_id'

  def up
    add_concurrent_index :packages_package_files, [:package_id, :status, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, name: INDEX_NAME
  end
end
