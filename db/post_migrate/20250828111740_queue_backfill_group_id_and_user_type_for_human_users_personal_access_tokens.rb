# frozen_string_literal: true

class QueueBackfillGroupIdAndUserTypeForHumanUsersPersonalAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillGroupIdAndUserTypeForHumanUsersPersonalAccessTokens"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205577
    #
    # queue_batched_background_migration(
    #   MIGRATION,
    #   :personal_access_tokens,
    #   :id,
    #   job_interval: DELAY_INTERVAL,
    #   batch_size: BATCH_SIZE,
    #   sub_batch_size: SUB_BATCH_SIZE
    # )
  end

  def down
    # no-op, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205577
    #
    # delete_batched_background_migration(MIGRATION, :personal_access_tokens, :id, [])
  end
end
