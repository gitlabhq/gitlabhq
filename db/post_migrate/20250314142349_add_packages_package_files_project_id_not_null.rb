# frozen_string_literal: true

class AddPackagesPackageFilesProjectIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_not_null_constraint :packages_package_files, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :packages_package_files, :project_id
  end
end
