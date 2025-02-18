# frozen_string_literal: true

class ValidateProjectsOrganizationIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_not_null_constraint(:projects, :organization_id)
  end

  def down
    # no-op
  end
end
