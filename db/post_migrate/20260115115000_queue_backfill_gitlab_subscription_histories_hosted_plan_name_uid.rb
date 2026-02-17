# frozen_string_literal: true

class QueueBackfillGitlabSubscriptionHistoriesHostedPlanNameUid < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillGitlabSubscriptionHistoriesHostedPlanNameUid"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :gitlab_subscription_histories,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :gitlab_subscription_histories, :id, [])
  end
end
