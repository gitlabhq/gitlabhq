# frozen_string_literal: true

class CreateVirtualRegistriesPackagesNpmCacheRemoteEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_npm_cache_remote_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (group_id)',
      primary_key: [:group_id, :iid] do |t|
      t.bigint :iid, null: false
      t.references :group,
        null: false,
        index: false, # part of the primary key, we don't need an index.
        foreign_key: { to_table: :namespaces }
      t.bigint :upstream_id, null: false
      t.bigint :downloads_count, null: false, default: 0
      t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
      t.datetime_with_timezone :downloaded_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :file_store, null: false, default: 1
      t.integer :size, null: false
      t.integer :status, null: false, default: 0, limit: 2
      t.binary :file_md5
      t.binary :file_sha1, null: false
      t.text :upstream_etag, limit: 255
      t.text :content_type, limit: 255, null: false, default: 'application/octet-stream'
      t.text :relative_path, null: false, limit: 1024
      t.text :file, null: false, limit: 1024
      t.text :object_storage_key, null: false, limit: 1024

      # for text search on relative path
      t.index :relative_path,
        using: :gin,
        opclass: :gin_trgm_ops,
        name: :i_vreg_pkgs_npm_cache_remote_entries_on_relative_path_trigram

      # for LFK update query when upstream is deleted
      t.index [:upstream_id, :status],
        name: :i_vreg_pkgs_npm_cache_remote_entries_upstream_id_and_status

      t.index [:relative_path, :object_storage_key, :group_id],
        name: :i_uniq_v_pkgs_npm_cache_rem_entrs_on_rel_path_obj_key_group_id,
        unique: true

      t.index [:upstream_id, :group_id, :relative_path],
        name: :i_uniq_v_pkg_npm_cache_rem_entrs_on_upstr_id_group_id_rel_path,
        where: 'status = 0',
        unique: true

      t.check_constraint '(file_md5 IS NULL OR octet_length(file_md5) = 16)'
      t.check_constraint '(octet_length(file_sha1) = 20)'
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
