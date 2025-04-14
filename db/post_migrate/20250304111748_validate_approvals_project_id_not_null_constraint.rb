# frozen_string_literal: true

class ValidateApprovalsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    validate_not_null_constraint :approvals, :project_id
  end

  def down
    # no-op
  end
end
