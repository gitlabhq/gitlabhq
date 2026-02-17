# frozen_string_literal: true

class AddRequiringCleanupIdxToVirtualRegistriesPackagesMavenCacheRemEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_cache_remote_entries
  INDEX_NAME = :index_vr_pkg_maven_cache_rem_entries_on_requiring_cleanup
  COLUMN_NAMES = %i[group_id iid downloaded_at].freeze

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      COLUMN_NAMES,
      name: INDEX_NAME,
      where: 'status = 0'
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
