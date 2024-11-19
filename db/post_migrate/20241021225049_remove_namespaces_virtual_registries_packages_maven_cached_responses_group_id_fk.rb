# frozen_string_literal: true

class RemoveNamespacesVirtualRegistriesPackagesMavenCachedResponsesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = 'fk_rails_0816e694a3'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:virtual_registries_packages_maven_cached_responses, :namespaces,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:virtual_registries_packages_maven_cached_responses, :namespaces,
      name: FOREIGN_KEY_NAME, column: :group_id,
      target_column: :id, on_delete: :cascade)
  end
end
