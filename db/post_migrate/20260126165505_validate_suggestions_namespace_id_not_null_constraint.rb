# frozen_string_literal: true

class ValidateSuggestionsNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_e69372e45f'

  def up
    validate_not_null_constraint :suggestions, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
