# frozen_string_literal: true

class AddPackagesBuildInfosProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :packages_build_infos, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :packages_build_infos, :project_id
  end
end
