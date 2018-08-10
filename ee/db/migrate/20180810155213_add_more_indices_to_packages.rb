class AddMoreIndicesToPackages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_files, [:package_id, :file_name]
    add_concurrent_index :packages_maven_metadata, :path
  end

  def down
    remove_concurrent_index :packages_package_files, [:package_id, :file_name]
    remove_concurrent_index :packages_maven_metadata, :path
  end
end
