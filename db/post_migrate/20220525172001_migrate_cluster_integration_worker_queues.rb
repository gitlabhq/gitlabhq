# frozen_string_literal: true

class MigrateClusterIntegrationWorkerQueues < Gitlab::Database::Migration[2.0]
  def up
    sidekiq_queue_migrate 'gcp_cluster:clusters_applications_activate_service',
      to: 'gcp_cluster:clusters_applications_activate_integration'
    sidekiq_queue_migrate 'gcp_cluster:clusters_applications_deactivate_service',
      to: 'gcp_cluster:clusters_applications_deactivate_integration'
  end

  def down
    sidekiq_queue_migrate 'gcp_cluster:clusters_applications_activate_integration',
      to: 'gcp_cluster:clusters_applications_activate_service'
    sidekiq_queue_migrate 'gcp_cluster:clusters_applications_deactivate_integration',
      to: 'gcp_cluster:clusters_applications_deactivate_service'
  end
end
