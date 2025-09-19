# frozen_string_literal: true

class CreateVirtualRegistriesContainerCacheEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.5'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_cache_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (relative_path)',
      primary_key: [:upstream_id, :relative_path, :status] do |t|
      t.references :group,
        null: false,
        index: true,
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
        name: :idx_vregs_container_cache_entries_on_relative_path_trigram

      # for cleanup jobs
      t.index [:upstream_id, :relative_path],
        name: :idx_vregs_container_cache_entries_on_upt_id_relpath,
        where: 'status = 2' # status: :pending_destruction

      t.index [:relative_path, :object_storage_key],
        name: :idx_vregs_container_cache_entries_on_uniq_object_storage_key,
        unique: true

      t.check_constraint '(file_md5 IS NULL OR octet_length(file_md5) = 16)'
      t.check_constraint '(octet_length(file_sha1) = 20)'
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME
  end
end
