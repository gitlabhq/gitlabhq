# frozen_string_literal: true

class AddIndexToVirtualRegistriesContainerCacheEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  milestone '18.5'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_cache_entries
  INDEX_UPSTREAM_CREATED = :idx_vregs_container_cache_entries_on_pending_upt_id_created_at

  def up
    # Index for default entries ordered by creation time
    add_concurrent_partitioned_index(
      TABLE_NAME,
      [:upstream_id, :created_at],
      name: INDEX_UPSTREAM_CREATED,
      where: 'status = 0' # status: :default
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(
      TABLE_NAME,
      INDEX_UPSTREAM_CREATED
    )
  end
end
