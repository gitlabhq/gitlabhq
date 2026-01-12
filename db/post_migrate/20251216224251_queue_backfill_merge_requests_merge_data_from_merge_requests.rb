# frozen_string_literal: true

class QueueBackfillMergeRequestsMergeDataFromMergeRequests < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  MIGRATION = "BackfillMergeRequestsMergeDataFromMergeRequests"

  def up
    # no-op because there was corrupted data in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218230
  end

  def down
    # no-op because there was corrupted data in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218230
  end
end
