# frozen_string_literal: true

class CreateDeploymentClusters < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :deployment_clusters, id: false, force: :cascade do |t|
      t.references :deployment, foreign_key: { on_delete: :cascade }, primary_key: true, type: :integer, index: false, default: nil
      t.references :cluster, foreign_key: { on_delete: :cascade }, type: :integer, index: false, null: false
      t.string :kubernetes_namespace, limit: 255

      t.index [:cluster_id, :kubernetes_namespace], name: 'idx_deployment_clusters_on_cluster_id_and_kubernetes_namespace'
      t.index [:cluster_id, :deployment_id], unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
