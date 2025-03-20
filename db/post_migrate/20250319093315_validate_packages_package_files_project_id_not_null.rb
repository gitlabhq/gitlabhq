# frozen_string_literal: true

class ValidatePackagesPackageFilesProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    validate_not_null_constraint :packages_package_files, :project_id, constraint_name: 'check_43773f06dc'
  end

  def down
    # no-op
  end
end
