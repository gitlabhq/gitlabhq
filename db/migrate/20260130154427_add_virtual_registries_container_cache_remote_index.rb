# frozen_string_literal: true

class AddVirtualRegistriesContainerCacheRemoteIndex < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :virtual_registries_container_cache_remote_entries
  INDEX_NAME = :idx_vreg_cont_cache_remote_lookup

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      %i[upstream_id group_id created_at],
      name: INDEX_NAME,
      order: { created_at: :desc },
      where: 'status = 0'
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
