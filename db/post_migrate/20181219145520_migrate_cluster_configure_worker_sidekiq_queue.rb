# frozen_string_literal: true

class MigrateClusterConfigureWorkerSidekiqQueue < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'gcp_cluster:cluster_platform_configure', to: 'gcp_cluster:cluster_configure'
  end

  def down
    sidekiq_queue_migrate 'gcp_cluster:cluster_configure', to: 'gcp_cluster:cluster_platform_configure'
  end
end
