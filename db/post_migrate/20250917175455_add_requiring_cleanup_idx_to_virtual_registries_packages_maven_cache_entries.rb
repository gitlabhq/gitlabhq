# frozen_string_literal: true

class AddRequiringCleanupIdxToVirtualRegistriesPackagesMavenCacheEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries
  COLUMN_NAMES = %i[upstream_id status relative_path downloaded_at].freeze
  INDEX_NAME = :idx_maven_cache_entries_requiring_cleanup_columns

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
