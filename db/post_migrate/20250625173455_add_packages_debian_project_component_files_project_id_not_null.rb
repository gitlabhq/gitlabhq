# frozen_string_literal: true

class AddPackagesDebianProjectComponentFilesProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_debian_project_component_files, :project_id
  end

  def down
    remove_not_null_constraint :packages_debian_project_component_files, :project_id
  end
end
