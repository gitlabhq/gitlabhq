# frozen_string_literal: true

class ValidateFkMergeRequestCleanupSchedulesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  FK_NAME = :fk_e0655f1a25

  # NOTE: follow up to https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201825 &&
  #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201986
  def up
    validate_foreign_key :merge_request_cleanup_schedules, :project_id, name: FK_NAME
  end

  def down
    # noop
  end
end
