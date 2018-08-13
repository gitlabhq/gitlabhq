class AddMoreIndicesToPackages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_files, [:package_id, :file_name]
    add_concurrent_index :packages_maven_metadata, :path, length: text_index_length
  end

  def down
    remove_concurrent_index :packages_package_files, [:package_id, :file_name]
    remove_concurrent_index :packages_maven_metadata, :path, length: text_index_length
  end

  private

  def text_index_length
    Gitlab::Database.mysql? ? 20 : nil
  end
end
