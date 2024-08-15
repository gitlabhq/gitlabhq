# frozen_string_literal: true

class QueueResolveVulnerabilitiesForRemovedAnalyzers < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "ResolveVulnerabilitiesForRemovedAnalyzers"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162527
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162527
  end
end
