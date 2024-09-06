# frozen_string_literal: true

class RemoveProjectsDastSiteProfileSecretVariablesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FK_NAME = "fk_6a254b170e"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dast_site_profile_secret_variables, :projects,
        name: FK_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:dast_site_profile_secret_variables, :projects,
      name: FK_NAME, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
