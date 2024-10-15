# frozen_string_literal: true

class RemoveProjectIdFkOnPackagesTerraformModuleMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  OLD_CONSTRAINT_NAME = 'fk_rails_d48f21a84b'

  # new foreign key added in ChangeProjectIdFkOnPackagesTerraformModuleMetadata
  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :packages_terraform_module_metadata,
        column: :project_id,
        on_delete: :nullify,
        name: OLD_CONSTRAINT_NAME
      )
    end
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(
      :packages_terraform_module_metadata,
      :projects,
      column: :project_id,
      on_delete: :nullify,
      name: OLD_CONSTRAINT_NAME
    )
  end
end
