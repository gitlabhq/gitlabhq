# frozen_string_literal: true

class ValidateAsyncForeignKeyOnApprovalMergeRequestRulesUsersProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # According to https://docs.gitlab.com/development/database/foreign_keys/#schedule-the-fk-to-be-validated
  # FK_NAME taken from https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200661
  FK_NAME = :fk_35e88790f5
  def up
    prepare_async_foreign_key_validation :approval_merge_request_rules_users, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :approval_merge_request_rules_users, name: FK_NAME
  end
end
