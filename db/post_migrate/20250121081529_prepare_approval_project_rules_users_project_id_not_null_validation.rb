# frozen_string_literal: true

class PrepareApprovalProjectRulesUsersProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_26058e3982

  def up
    prepare_async_check_constraint_validation :approval_project_rules_users, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :approval_project_rules_users, name: CONSTRAINT_NAME
  end
end
