# frozen_string_literal: true

class DropVirtualRegistriesPackagesMavenCacheLocalEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_maven_cache_local_entries

  def up
    drop_table TABLE_NAME
  end

  def down
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (relative_path)',
      primary_key: [:upstream_id, :relative_path] do |t|
      t.bigint :group_id, null: false,
        index: { name: 'idx_vreg_pkgs_maven_cache_local_entries_on_group_id' }
      t.bigint :upstream_id, null: false
      t.bigint :package_file_id,
        null: false,
        index: { name: 'idx_vreg_pkgs_maven_cache_local_entries_on_package_file_id' }
      t.timestamps_with_timezone null: false
      t.text :relative_path, null: false, limit: 1024
    end

    create_hash_partitions(TABLE_NAME, 16)
  end
end
