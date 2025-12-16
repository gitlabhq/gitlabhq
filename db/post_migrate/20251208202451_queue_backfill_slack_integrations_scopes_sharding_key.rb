# frozen_string_literal: true

class QueueBackfillSlackIntegrationsScopesShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillSlackIntegrationsScopesShardingKey"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 50

  def up
    queue_batched_background_migration(
      MIGRATION,
      :slack_integrations_scopes,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :slack_integrations_scopes, :id, [])
  end
end
