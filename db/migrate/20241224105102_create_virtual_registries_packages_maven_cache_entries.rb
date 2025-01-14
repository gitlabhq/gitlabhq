# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenCacheEntries < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.8'

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (relative_path)',
      primary_key: [:upstream_id, :relative_path, :status] do |t|
      t.bigint :group_id, null: false
      t.bigint :upstream_id, null: false
      t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :file_store, null: false, default: 1
      t.integer :size, null: false
      t.integer :status, null: false, default: 0, limit: 2
      t.text :relative_path, null: false, limit: 1024
      t.text :file, null: false, limit: 1024
      t.text :object_storage_key, null: false, limit: 1024
      t.text :upstream_etag, limit: 255
      t.text :content_type, limit: 255, null: false, default: 'application/octet-stream'
      t.text :file_final_path, limit: 1024
      t.binary :file_md5
      t.binary :file_sha1, null: false

      # for text search on relative path
      t.index :relative_path,
        using: :gin,
        opclass: :gin_trgm_ops,
        name: :idx_vreg_pkgs_maven_cache_entries_on_relative_path_trigram

      # index on sharding key
      t.index %i[group_id status], name: :idx_vreg_pkgs_maven_cache_entries_on_group_id_status

      # for cleanup jobs
      t.index [:upstream_id, :relative_path],
        name: :idx_vregs_pkgs_mvn_cache_entries_on_pending_upt_id_relpath,
        where: 'status = 2' # status: :pending_destruction

      # for ordered pagination
      t.index [:upstream_id, :created_at],
        name: :idx_vregs_pkgs_mvn_cache_entries_on_pending_upt_id_created_at,
        where: 'status = 0' # status: :default
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME
  end
end
