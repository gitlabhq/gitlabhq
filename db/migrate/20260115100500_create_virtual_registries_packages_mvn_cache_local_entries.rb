# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMvnCacheLocalEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_cache_local_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (group_id)',
      primary_key: [:group_id, :iid] do |t|
      t.bigint :iid, null: false # used as a row tie breaker
      t.references :group,
        null: false,
        index: false, # part of the primary key, we don't need an index.
        foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.references :upstream,
        null: false,
        index: false, # the unique index on L32 already cover this
        foreign_key: { to_table: :virtual_registries_packages_maven_local_upstreams, on_delete: :cascade }
      t.references :package_file,
        null: false,
        index: { name: 'idx_vreg_pkgs_maven_cache_local_entries_on_package_file_id' },
        foreign_key: { to_table: :packages_package_files, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
      t.text :relative_path, null: false, limit: 1024

      t.index %i[upstream_id group_id relative_path],
        unique: true,
        name: :idx_uniq_vreg_mvn_cache_local_entries_on_upstream_id_rel_path
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
