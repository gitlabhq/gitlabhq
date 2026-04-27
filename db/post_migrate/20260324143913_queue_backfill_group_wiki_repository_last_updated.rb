# frozen_string_literal: true

class QueueBackfillGroupWikiRepositoryLastUpdated < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillGroupWikiRepositoryLastUpdated"
  SUB_BATCH_SIZE = 100

  def up
    # no-op because there was a bug in the original migration
    # fixed-by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231783
  end

  def down
    # no-op because there was a bug in the original migration
    # fixed-by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231783
  end
end
