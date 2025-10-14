# frozen_string_literal: true

class QueueBackfillSubscriptionUserAddOnAssignmentVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.3'

  MIGRATION = "BackfillSubscriptionUserAddOnAssignmentVersions"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE     = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op, there were more orphan records that needs to have assigment version created.
    # Fixed by: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203303
  end

  def down
    # no-op, there were more orphan records that needs to have assigment version created.
    # Fixed by: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203303
  end
end
