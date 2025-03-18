# frozen_string_literal: true

class AddVersionPartsToPackagesTerraformModuleMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    with_lock_retries do
      add_column :packages_terraform_module_metadata, :semver_major, :integer
      add_column :packages_terraform_module_metadata, :semver_minor, :integer
      add_column :packages_terraform_module_metadata, :semver_patch, :integer
      add_column :packages_terraform_module_metadata, :semver_prerelease, :text
    end

    add_text_limit :packages_terraform_module_metadata, :semver_prerelease, 255
  end

  def down
    with_lock_retries do
      remove_column :packages_terraform_module_metadata, :semver_major, :integer
      remove_column :packages_terraform_module_metadata, :semver_minor, :integer
      remove_column :packages_terraform_module_metadata, :semver_patch, :integer
      remove_column :packages_terraform_module_metadata, :semver_prerelease, :text
    end
  end
end
