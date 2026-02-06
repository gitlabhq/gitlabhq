# frozen_string_literal: true

# This migration backfills display_gitlab_credits_user_data to true for all
# top-level groups on GitLab.com. Self-managed instances don't need this
# because they only have one application_settings record which is handled
# by a separate migration.

class QueueBackfillDisplayGitlabCreditsUserDataForNamespaceSetting < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillDisplayGitlabCreditsUserDataForNamespaceSetting"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    return unless Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :namespace_settings,
      :namespace_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :namespace_settings, :namespace_id, [])
  end
end
