# frozen_string_literal: true

class ValidateListsParentNotNullConstraint < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_6dadb82d36'

  milestone '18.1'

  def up
    validate_multi_column_not_null_constraint :lists, :group_id, :project_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
