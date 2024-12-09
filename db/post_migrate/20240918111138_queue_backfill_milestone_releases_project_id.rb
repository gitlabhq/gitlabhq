# frozen_string_literal: true

class QueueBackfillMilestoneReleasesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillMilestoneReleasesProjectId"

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170694
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170694
  end
end
