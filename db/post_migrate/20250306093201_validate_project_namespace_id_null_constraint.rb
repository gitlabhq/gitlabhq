# frozen_string_literal: true

class ValidateProjectNamespaceIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :projects, :project_namespace_id
  end

  def down
    # no-op
  end
end
