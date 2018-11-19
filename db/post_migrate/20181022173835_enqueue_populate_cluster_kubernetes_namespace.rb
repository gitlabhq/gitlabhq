# frozen_string_literal: true

class EnqueuePopulateClusterKubernetesNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'PopulateClusterKubernetesNamespaceTable'.freeze

  disable_ddl_transaction!

  def up
    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
    Clusters::KubernetesNamespace.delete_all
  end
end
