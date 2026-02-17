# frozen_string_literal: true

class QueueBackfillClustersKubernetesNamespacesShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillClustersKubernetesNamespacesShardingKey"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :clusters_kubernetes_namespaces,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :clusters_kubernetes_namespaces, :id, [])
  end
end
