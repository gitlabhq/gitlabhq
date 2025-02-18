# frozen_string_literal: true

class ValidateApprovalProjectRulesUsersProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :approval_project_rules_users, :project_id
  end

  def down
    # no-op
  end
end
