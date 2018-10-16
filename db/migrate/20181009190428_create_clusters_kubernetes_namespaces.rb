# frozen_string_literal: true

class CreateClustersKubernetesNamespaces < ActiveRecord::Migration
  DOWNTIME = false
  INDEX_NAME = 'kubernetes_namespaces_cluster_project_and_namespace'

  def change
    create_table :clusters_kubernetes_namespaces do |t|
      t.references :cluster_project, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false

      t.text :encrypted_service_account_token
      t.string :encrypted_service_account_token_iv

      t.string :namespace, null: false
      t.string :service_account_name
    end

    add_index :clusters_kubernetes_namespaces, [:cluster_project_id, :namespace],
      unique: true,
      name: INDEX_NAME
  end
end
