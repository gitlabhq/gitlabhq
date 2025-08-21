# frozen_string_literal: true

class ValidateAsyncForeignKeyOnMergeRequestCleanupSchedulesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # According to https://docs.gitlab.com/development/database/foreign_keys/#schedule-the-fk-to-be-validated
  # FK_NAME taken from https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201825/diffs#diff-content-2b082fc1831991d48d393026c0c6a4283cb3d159
  FK_NAME = :fk_e0655f1a25
  def up
    prepare_async_foreign_key_validation :merge_request_cleanup_schedules, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :merge_request_cleanup_schedules, name: FK_NAME
  end
end
