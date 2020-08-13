# frozen_string_literal: true

class AddPartialIndexOnIdToPackageFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_packages_package_files_file_store_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_files, :id, where: 'file_store IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end
