class CreateClustersKubernetesHelmApps < ActiveRecord::Migration
  def change
    create_table :clusters_kubernetes_helm_apps do |t|
      t.integer :status, null: false

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.references :service, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.string :version, null: false
      t.text :status_reason
    end
  end
end
