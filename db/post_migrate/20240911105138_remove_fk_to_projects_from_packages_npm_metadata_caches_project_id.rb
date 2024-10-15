# frozen_string_literal: true

class RemoveFkToProjectsFromPackagesNpmMetadataCachesProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  FOREIGN_KEY_NAME = 'fk_ada23b1d30'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :packages_npm_metadata_caches,
        :projects,
        name: FOREIGN_KEY_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :packages_npm_metadata_caches,
      :projects,
      name: FOREIGN_KEY_NAME,
      column: :project_id,
      target_column: :id,
      on_delete: :nullify,
      reverse_lock_order: true
    )
  end
end
