# frozen_string_literal: true

class ValidateApprovalMergeRequestRulesUsersProjectIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    validate_not_null_constraint :approval_merge_request_rules_users, :project_id, constraint_name: :check_eca70345f1
  end

  def down
    # no-op
  end
end
