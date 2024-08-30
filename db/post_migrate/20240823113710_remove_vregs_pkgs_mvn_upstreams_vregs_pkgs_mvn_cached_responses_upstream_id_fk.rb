# frozen_string_literal: true

class RemoveVregsPkgsMvnUpstreamsVregsPkgsMvnCachedResponsesUpstreamIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = 'fk_rails_1167f21441'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :virtual_registries_packages_maven_cached_responses,
        :virtual_registries_packages_maven_upstreams,
        name: FOREIGN_KEY_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :virtual_registries_packages_maven_cached_responses,
      :virtual_registries_packages_maven_upstreams,
      name: FOREIGN_KEY_NAME,
      column: :upstream_id,
      target_column: :id,
      on_delete: :nullify
    )
  end
end
