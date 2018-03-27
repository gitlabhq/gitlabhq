class CreateClustersKubernetesHelmApps < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :clusters_applications_helm do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.integer :status, null: false
      t.string :version, null: false
      t.text :status_reason
    end
  end
end
