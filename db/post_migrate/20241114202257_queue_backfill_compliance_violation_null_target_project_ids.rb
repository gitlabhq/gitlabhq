# frozen_string_literal: true

class QueueBackfillComplianceViolationNullTargetProjectIds < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
    # Requeued by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180053
  end

  def down
    # noop
    # Requeued by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180053
  end
end
