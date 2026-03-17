# frozen_string_literal: true

class AddIndexToVirtualRegistriesMavenCacheRemoteEntryStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cache_remote_entry_states
  NEW_INDEX_NAME = 'idx_vreg_mvn_cache_remote_entry_states_on_group_id_and_iid'
  OLD_INDEX_NAME = 'idx_vreg_mvn_cache_remote_entry_states_on_group_id'

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:group_id, :virtual_registries_packages_maven_cache_remote_entry_iid],
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :group_id, name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
