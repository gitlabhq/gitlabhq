# frozen_string_literal: true

class QueueCreateMissingExternalLinksForVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "CreateMissingExternalLinksForVulnerabilities"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op
    # will be fixed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172843
  end

  def down
    # no-op
    # will be fixed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172843
  end
end
