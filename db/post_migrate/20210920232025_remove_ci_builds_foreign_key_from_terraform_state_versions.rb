# frozen_string_literal: true

class RemoveCiBuildsForeignKeyFromTerraformStateVersions < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:terraform_state_versions, :ci_builds)
    end
  end

  def down
    add_concurrent_foreign_key(:terraform_state_versions, :ci_builds, column: :ci_build_id, on_delete: :nullify)
  end
end
