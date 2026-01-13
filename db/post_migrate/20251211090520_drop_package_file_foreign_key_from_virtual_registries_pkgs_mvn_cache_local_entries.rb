# frozen_string_literal: true

class DropPackageFileForeignKeyFromVirtualRegistriesPkgsMvnCacheLocalEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_maven_cache_local_entries
  REFERENCED_TABLE_NAME = :packages_package_files
  COLUMN_NAME = :package_file_id

  def up
    remove_partitioned_foreign_key TABLE_NAME, REFERENCED_TABLE_NAME, column: COLUMN_NAME
  end

  def down
    add_concurrent_partitioned_foreign_key TABLE_NAME, REFERENCED_TABLE_NAME, column: COLUMN_NAME
  end
end
