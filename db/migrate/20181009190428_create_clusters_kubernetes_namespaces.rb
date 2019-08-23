# frozen_string_literal: true

class CreateClustersKubernetesNamespaces < ActiveRecord::Migration[4.2]
  DOWNTIME = false
  INDEX_NAME = 'kubernetes_namespaces_cluster_and_namespace'

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :clusters_kubernetes_namespaces, id: :bigserial do |t|
      t.references :cluster, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, foreign_key: { on_delete: :nullify }
      t.references :cluster_project, index: true, foreign_key: { on_delete: :nullify }

      t.timestamps_with_timezone null: false

      t.string :encrypted_service_account_token_iv
      t.string :namespace, null: false
      t.string :service_account_name

      t.text :encrypted_service_account_token

      t.index [:cluster_id, :namespace], name: INDEX_NAME, unique: true
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
