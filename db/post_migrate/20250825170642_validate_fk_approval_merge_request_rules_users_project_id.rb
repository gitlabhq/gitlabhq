# frozen_string_literal: true

class ValidateFkApprovalMergeRequestRulesUsersProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  FK_NAME = :fk_35e88790f5

  # NOTE: follow up to https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202062
  def up
    validate_foreign_key :approval_merge_request_rules_users, :project_id, name: FK_NAME
  end

  def down
    # noop
  end
end
