# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenCacheLocalEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '18.6'

  TABLE_NAME = :virtual_registries_packages_maven_cache_local_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (relative_path)',
      primary_key: [:upstream_id, :relative_path] do |t|
      t.references :group,
        null: false,
        index: { name: 'idx_vreg_pkgs_maven_cache_local_entries_on_group_id' },
        foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.references :upstream,
        null: false,
        index: false,
        foreign_key: { to_table: :virtual_registries_packages_maven_upstreams, on_delete: :cascade }
      t.references :package_file,
        null: false,
        index: { name: 'idx_vreg_pkgs_maven_cache_local_entries_on_package_file_id' },
        foreign_key: { to_table: :packages_package_files, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :relative_path, null: false, limit: 1024
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
