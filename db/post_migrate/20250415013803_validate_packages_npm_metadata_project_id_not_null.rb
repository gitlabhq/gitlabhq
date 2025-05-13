# frozen_string_literal: true

class ValidatePackagesNpmMetadataProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    validate_not_null_constraint :packages_npm_metadata, :project_id, constraint_name: 'check_8d2e047947'
  end

  def down
    # no-op
  end
end
