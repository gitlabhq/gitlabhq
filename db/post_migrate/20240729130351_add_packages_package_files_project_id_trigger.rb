# frozen_string_literal: true

class AddPackagesPackageFilesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_package_files,
      sharding_key: :project_id,
      parent_table: :packages_packages,
      parent_sharding_key: :project_id,
      foreign_key: :package_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_package_files,
      sharding_key: :project_id,
      parent_table: :packages_packages,
      parent_sharding_key: :project_id,
      foreign_key: :package_id
    )
  end
end
