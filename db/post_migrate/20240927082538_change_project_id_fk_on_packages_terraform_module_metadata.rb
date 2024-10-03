# frozen_string_literal: true

class ChangeProjectIdFkOnPackagesTerraformModuleMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  NEW_CONSTRAINT_NAME = 'fk_rails_terraform_module_metadata_project_id'

  def up
    add_concurrent_foreign_key(:packages_terraform_module_metadata, :projects, column: :project_id,
      on_delete: :cascade, name: NEW_CONSTRAINT_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:packages_terraform_module_metadata, column: :project_id, on_delete: :cascade,
        name: NEW_CONSTRAINT_NAME)
    end
  end
end
