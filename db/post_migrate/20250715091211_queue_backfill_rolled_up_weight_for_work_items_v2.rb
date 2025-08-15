# frozen_string_literal: true

class QueueBackfillRolledUpWeightForWorkItemsV2 < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op: re-enqueued in a new migration: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200713
  end

  def down
    # no-op
  end
end
