# frozen_string_literal: true

class ValidateNamespacesOrganizationIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    validate_not_null_constraint :namespaces, :organization_id
  end

  def down
    # no-op
  end
end
