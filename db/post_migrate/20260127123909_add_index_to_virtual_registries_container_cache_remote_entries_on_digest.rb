# frozen_string_literal: true

class AddIndexToVirtualRegistriesContainerCacheRemoteEntriesOnDigest < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  disable_ddl_transaction!
  milestone '18.9'

  TABLE = :virtual_registries_container_cache_remote_entries
  INDEX = :idx_vregs_container_cache_remote_entries_on_digest

  def up
    add_concurrent_partitioned_index TABLE, %i[digest], name: INDEX
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE, INDEX
  end
end
