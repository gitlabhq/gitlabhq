# frozen_string_literal: true

class UpdateGroupIdIndexOnVirtualRegistryContainer < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.7'

  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_cache_entries
  NEW_INDEX_NAME = 'idx_vregs_container_cache_entries_on_group_id_upstream_etag'
  OLD_INDEX_NAME = 'index_virtual_registries_container_cache_entries_on_group_id'
  INDEX_COLUMNS = [:group_id, :upstream_etag]

  INDEXES = [
    { table: :virtual_registries_container_cache_entries_00,
      old_name: :index_34f9e5bd61,
      new_name: :virtual_registries_container_cache_entries_00_group_id_idx },
    { table: :virtual_registries_container_cache_entries_01,
      old_name: :index_8824e6cb6c,
      new_name: :virtual_registries_container_cache_entries_01_group_id_idx },
    { table: :virtual_registries_container_cache_entries_02,
      old_name: :index_31a37a10aa,
      new_name: :virtual_registries_container_cache_entries_02_group_id_idx },
    { table: :virtual_registries_container_cache_entries_03,
      old_name: :index_fe3ae4f572,
      new_name: :virtual_registries_container_cache_entries_03_group_id_idx },
    { table: :virtual_registries_container_cache_entries_04,
      old_name: :index_d99028887f,
      new_name: :virtual_registries_container_cache_entries_04_group_id_idx },
    { table: :virtual_registries_container_cache_entries_05,
      old_name: :index_7a6953d38f,
      new_name: :virtual_registries_container_cache_entries_05_group_id_idx },
    { table: :virtual_registries_container_cache_entries_06,
      old_name: :index_90700d983f,
      new_name: :virtual_registries_container_cache_entries_06_group_id_idx },
    { table: :virtual_registries_container_cache_entries_07,
      old_name: :index_066f7dcc66,
      new_name: :virtual_registries_container_cache_entries_07_group_id_idx },
    { table: :virtual_registries_container_cache_entries_08,
      old_name: :index_c3a8df71e3,
      new_name: :virtual_registries_container_cache_entries_08_group_id_idx },
    { table: :virtual_registries_container_cache_entries_09,
      old_name: :index_d9f67417e0,
      new_name: :virtual_registries_container_cache_entries_09_group_id_idx },
    { table: :virtual_registries_container_cache_entries_10,
      old_name: :index_f47ffe0b91,
      new_name: :virtual_registries_container_cache_entries_10_group_id_idx },
    { table: :virtual_registries_container_cache_entries_11,
      old_name: :index_4789dbadc9,
      new_name: :virtual_registries_container_cache_entries_11_group_id_idx },
    { table: :virtual_registries_container_cache_entries_12,
      old_name: :index_b725d78bf8,
      new_name: :virtual_registries_container_cache_entries_12_group_id_idx },
    { table: :virtual_registries_container_cache_entries_13,
      old_name: :index_888dc4f2c7,
      new_name: :virtual_registries_container_cache_entries_13_group_id_idx },
    { table: :virtual_registries_container_cache_entries_14,
      old_name: :index_4519b501df,
      new_name: :virtual_registries_container_cache_entries_14_group_id_idx },
    { table: :virtual_registries_container_cache_entries_15,
      old_name: :index_2c6ca7bc0c,
      new_name: :virtual_registries_container_cache_entries_15_group_id_idx }
  ].freeze

  def up
    add_concurrent_partitioned_index TABLE_NAME, INDEX_COLUMNS, name: NEW_INDEX_NAME
    remove_concurrent_partitioned_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index TABLE_NAME, :group_id, name: OLD_INDEX_NAME

    INDEXES.each do |index|
      if index_exists?("gitlab_partitions_static.#{index[:table]}", :group_id, name: index[:old_name])
        rename_index_with_schema(index[:table], index[:old_name], index[:new_name],
          schema: :gitlab_partitions_static)
      end
    end

    remove_concurrent_partitioned_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
