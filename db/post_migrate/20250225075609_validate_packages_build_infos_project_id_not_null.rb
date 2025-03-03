# frozen_string_literal: true

class ValidatePackagesBuildInfosProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :packages_build_infos, :project_id, constraint_name: 'check_d979c653e1'
  end

  def down
    # no-op
  end
end
