# frozen_string_literal: true

# trigger_489fffe04425 copies project_id from packages_helm_metadata_caches, which is
# cleaned up by a loose FK and so may hold a deleted project's id. A hard FK here
# rejects those writes. See https://gitlab.com/gitlab-org/gitlab/-/issues/605940
class RemoveProjectIdForeignKeyFromPackagesHelmMetadataCacheStates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_2902beee34'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :packages_helm_metadata_cache_states, :projects,
        column: :project_id, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :packages_helm_metadata_cache_states, :projects,
      column: :project_id, on_delete: :cascade, name: CONSTRAINT_NAME, reverse_lock_order: true
  end
end
