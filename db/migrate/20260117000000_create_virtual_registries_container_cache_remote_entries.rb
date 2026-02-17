# frozen_string_literal: true

class CreateVirtualRegistriesContainerCacheRemoteEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :virtual_registries_container_cache_remote_entries

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (group_id)',
      primary_key: %i[group_id iid] do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
      t.datetime_with_timezone :downloaded_at, null: false, default: -> { 'NOW()' }
      t.bigint :iid, null: false
      t.references :group,
        null: false,
        index: false, # already indexed by the primary key
        foreign_key: { to_table: :namespaces }
      t.bigint :upstream_id, null: false
      t.bigint :downloads_count, default: 0, null: false

      t.integer :size, null: false
      t.integer :file_store, limit: 2, default: 1, null: false
      t.integer :status, limit: 2, default: 0, null: false

      t.binary :file_sha1, null: false

      t.text :relative_path, null: false, limit: 1024
      t.text :object_storage_key, null: false, limit: 1024
      t.text :upstream_etag, limit: 255
      t.text :content_type, limit: 255, null: false, default: 'application/octet-stream'
      t.text :file, null: false, limit: 1024

      t.index %i[group_id relative_path object_storage_key],
        unique: true,
        name: :idx_uniq_vreg_cont_cache_remote_rel_path_key

      t.index %i[group_id upstream_id relative_path],
        unique: true,
        where: 'status = 0',
        name: :idx_uniq_vreg_cont_cache_remote_upstream_rel_path

      # for text search on relative path
      t.index :relative_path,
        using: :gin,
        opclass: :gin_trgm_ops,
        name: :idx_vreg_cont_cache_remote_rel_path_trigram

      # for LFK update query when upstream is deleted
      t.index %i[upstream_id status],
        name: :idx_vreg_cont_cache_remote_upstream_status

      t.check_constraint '(octet_length(file_sha1) = 20)'
    end

    create_hash_partitions(TABLE_NAME, 16)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
