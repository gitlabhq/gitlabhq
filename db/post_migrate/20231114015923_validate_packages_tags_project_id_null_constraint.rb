# frozen_string_literal: true

class ValidatePackagesTagsProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def up
    validate_not_null_constraint :packages_tags, :project_id
  end

  def down
    # no-op
  end
end
