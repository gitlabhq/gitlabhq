# frozen_string_literal: true

class CreateVirtualRegistriesPackagesNpmCacheLocalEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_npm_cache_local_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (group_id)',
      primary_key: [:group_id, :iid] do |t|
      t.bigint :iid, null: false
      t.references :group,
        null: false,
        index: false, # part of the primary key, we don't need an index.
        foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.references :upstream,
        null: false,
        index: false, # covered by i_uniq_v_pkg_npm_cache_loc_entrs_on_upstr_id_group_id_rel_path
        foreign_key: { to_table: :virtual_registries_packages_npm_upstreams, on_delete: :cascade }
      t.references :package_file,
        null: false,
        index: { name: 'idx_vreg_pkgs_npm_cache_local_entries_on_package_file_id' },
        foreign_key: { to_table: :packages_package_files, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :relative_path, null: false, limit: 1024

      t.index [:upstream_id, :group_id, :relative_path],
        unique: true,
        name: :i_uniq_v_pkg_npm_cache_loc_entrs_on_upstr_id_group_id_rel_path
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
