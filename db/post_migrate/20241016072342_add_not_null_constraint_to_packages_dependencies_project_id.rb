# frozen_string_literal: true

class AddNotNullConstraintToPackagesDependenciesProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_not_null_constraint :packages_dependencies, :project_id
  end

  def down
    remove_not_null_constraint :packages_dependencies, :project_id
  end
end
