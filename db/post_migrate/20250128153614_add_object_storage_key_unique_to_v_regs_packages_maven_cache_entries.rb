# frozen_string_literal: true

class AddObjectStorageKeyUniqueToVRegsPackagesMavenCacheEntries < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.9'

  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries
  COLUMNS = [:relative_path, :object_storage_key]
  INDEX_NAME = :idx_vregs_pkgs_mvn_cache_entries_on_uniq_object_storage_key

  def up
    truncate_tables!(TABLE_NAME.to_s)
    add_concurrent_partitioned_index TABLE_NAME, COLUMNS, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end
end
