# frozen_string_literal: true

class AddFkCdArtifactSourcesToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_artifact_sources, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_artifact_sources, column: :organization_id
    end
  end
end
