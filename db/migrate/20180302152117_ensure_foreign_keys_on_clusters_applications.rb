# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnsureForeignKeysOnClustersApplications < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    existing = Clusters::Cluster
      .joins(:application_ingress)
      .where('clusters.id = clusters_applications_ingress.cluster_id')

    Clusters::Applications::Ingress.where('NOT EXISTS (?)', existing).in_batches do |batch|
      batch.delete_all
    end

    unless foreign_keys_for(:clusters_applications_ingress, :cluster_id).any?
      add_concurrent_foreign_key :clusters_applications_ingress, :clusters,
        column: :cluster_id,
        on_delete: :cascade
    end

    existing = Clusters::Cluster
      .joins(:application_prometheus)
      .where('clusters.id = clusters_applications_prometheus.cluster_id')

    Clusters::Applications::Ingress.where('NOT EXISTS (?)', existing).in_batches do |batch|
      batch.delete_all
    end

    unless foreign_keys_for(:clusters_applications_prometheus, :cluster_id).any?
      add_concurrent_foreign_key :clusters_applications_prometheus, :clusters,
        column: :cluster_id,
        on_delete: :cascade
    end
  end

  def down
    if foreign_keys_for(:clusters_applications_ingress, :cluster_id).any?
      remove_foreign_key :clusters_applications_ingress, column: :cluster_id
    end

    if foreign_keys_for(:clusters_applications_prometheus, :cluster_id).any?
      remove_foreign_key :clusters_applications_prometheus, column: :cluster_id
    end
  end
end
