# frozen_string_literal: true

class CreateClustersKubernetesNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table(:clusters_kubernetes_namespaces) do |t|
      t.references :cluster_project, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false

      t.text :encrypted_service_account_token

      t.string :namespace, null: false
      t.string :service_account_name
    end
  end
end
