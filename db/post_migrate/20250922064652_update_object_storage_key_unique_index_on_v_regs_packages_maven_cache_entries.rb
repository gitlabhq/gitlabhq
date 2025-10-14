# frozen_string_literal: true

class UpdateObjectStorageKeyUniqueIndexOnVRegsPackagesMavenCacheEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries
  NEW_INDEX_NAME = :i_v_pkgs_mvn_cache_entries_on_uniq_object_storage_key_group_id
  OLD_INDEX_NAME = :idx_vregs_pkgs_mvn_cache_entries_on_uniq_object_storage_key

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      %i[relative_path object_storage_key group_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(
      TABLE_NAME,
      %i[relative_path object_storage_key],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_partitioned_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
