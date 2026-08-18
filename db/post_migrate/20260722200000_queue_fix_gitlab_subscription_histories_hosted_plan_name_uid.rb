# frozen_string_literal: true

class QueueFixGitlabSubscriptionHistoriesHostedPlanNameUid < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "FixGitlabSubscriptionHistoriesHostedPlanNameUid"
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 500

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
