# frozen_string_literal: true

class AddFkToVirtualRegistriesMavenCacheRemoteEntryStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :virtual_registries_packages_maven_cache_remote_entry_states,
      :virtual_registries_packages_maven_cache_remote_entries,
      column: [:group_id, :virtual_registries_packages_maven_cache_remote_entry_iid],
      target_column: [:group_id, :iid],
      on_delete: :cascade
    )
  end

  def down
    remove_foreign_key_if_exists(
      :virtual_registries_packages_maven_cache_remote_entry_states,
      :virtual_registries_packages_maven_cache_remote_entries,
      column: [:group_id, :virtual_registries_packages_maven_cache_remote_entry_iid]
    )
  end
end
