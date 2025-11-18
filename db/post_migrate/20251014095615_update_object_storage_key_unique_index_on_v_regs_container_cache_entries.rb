# frozen_string_literal: true

class UpdateObjectStorageKeyUniqueIndexOnVRegsContainerCacheEntries < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :virtual_registries_container_cache_entries
  NEW_INDEX_NAME = :i_v_container_cache_entries_on_uniq_object_storage_key_group_id
  OLD_INDEX_NAME = :idx_vregs_container_cache_entries_on_uniq_object_storage_key
  INDEXES = [
    { table: :virtual_registries_container_cache_entries_00,
      old_name: :index_924649ecf2,
      new_name: :virtual_registries_container__relative_path_object_storage__idx },
    { table: :virtual_registries_container_cache_entries_01,
      old_name: :index_b550483a13,
      new_name: :virtual_registries_container__relative_path_object_storage_idx1 },
    { table: :virtual_registries_container_cache_entries_02,
      old_name: :index_469673f558,
      new_name: :virtual_registries_container__relative_path_object_storage_idx2 },
    { table: :virtual_registries_container_cache_entries_03,
      old_name: :index_681de214f5,
      new_name: :virtual_registries_container__relative_path_object_storage_idx3 },
    { table: :virtual_registries_container_cache_entries_04,
      old_name: :index_34ff82fe83,
      new_name: :virtual_registries_container__relative_path_object_storage_idx4 },
    { table: :virtual_registries_container_cache_entries_05,
      old_name: :index_947bbcf9ce,
      new_name: :virtual_registries_container__relative_path_object_storage_idx5 },
    { table: :virtual_registries_container_cache_entries_06,
      old_name: :index_48d03843f8,
      new_name: :virtual_registries_container__relative_path_object_storage_idx6 },
    { table: :virtual_registries_container_cache_entries_07,
      old_name: :index_5d0cb9ba15,
      new_name: :virtual_registries_container__relative_path_object_storage_idx7 },
    { table: :virtual_registries_container_cache_entries_08,
      old_name: :index_918454f6c8,
      new_name: :virtual_registries_container__relative_path_object_storage_idx8 },
    { table: :virtual_registries_container_cache_entries_09,
      old_name: :index_7992356308,
      new_name: :virtual_registries_container__relative_path_object_storage_idx9 },
    { table: :virtual_registries_container_cache_entries_10,
      old_name: :index_504d6eb20d,
      new_name: :virtual_registries_container_relative_path_object_storage_idx10 },
    { table: :virtual_registries_container_cache_entries_11,
      old_name: :index_1021b3d367,
      new_name: :virtual_registries_container_relative_path_object_storage_idx11 },
    { table: :virtual_registries_container_cache_entries_12,
      old_name: :index_d1e1786944,
      new_name: :virtual_registries_container_relative_path_object_storage_idx12 },
    { table: :virtual_registries_container_cache_entries_13,
      old_name: :index_bce36d015a,
      new_name: :virtual_registries_container_relative_path_object_storage_idx13 },
    { table: :virtual_registries_container_cache_entries_14,
      old_name: :index_7fcab364cb,
      new_name: :virtual_registries_container_relative_path_object_storage_idx14 },
    { table: :virtual_registries_container_cache_entries_15,
      old_name: :index_bc79f041b7,
      new_name: :virtual_registries_container_relative_path_object_storage_idx15 }
  ].freeze

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

    INDEXES.each do |index|
      rename_index_with_schema(index[:table], index[:old_name], index[:new_name], schema: :gitlab_partitions_static)
    end

    remove_concurrent_partitioned_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
