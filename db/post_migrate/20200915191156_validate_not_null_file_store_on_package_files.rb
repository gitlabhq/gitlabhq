# frozen_string_literal: true

class ValidateNotNullFileStoreOnPackageFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Remove index which was only added to fill file_store
  INDEX_NAME = 'index_packages_package_files_file_store_is_null'
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :packages_package_files, :file_store

    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end

  def down
    add_concurrent_index :packages_package_files, :id, where: 'file_store IS NULL', name: INDEX_NAME
  end
end
