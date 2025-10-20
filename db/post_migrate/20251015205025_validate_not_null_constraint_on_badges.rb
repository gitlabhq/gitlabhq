# frozen_string_literal: true

class ValidateNotNullConstraintOnBadges < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_22ac1b6d3a'

  def up
    validate_multi_column_not_null_constraint(
      :badges,
      :group_id,
      :project_id,
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    # no-op
  end
end
