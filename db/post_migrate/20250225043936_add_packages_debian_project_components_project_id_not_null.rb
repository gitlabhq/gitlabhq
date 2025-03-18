# frozen_string_literal: true

class AddPackagesDebianProjectComponentsProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_debian_project_components, :project_id
  end

  def down
    remove_not_null_constraint :packages_debian_project_components, :project_id
  end
end
