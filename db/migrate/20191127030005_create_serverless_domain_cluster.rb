# frozen_string_literal: true

class CreateServerlessDomainCluster < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :serverless_domain_cluster, id: false, primary_key: :uuid do |t|
      t.references :pages_domain, null: false, foreign_key: { on_delete: :cascade }
      t.references :clusters_applications_knative, null: false,
                   foreign_key: { to_table: :clusters_applications_knative, on_delete: :cascade },
                   index: { name: :idx_serverless_domain_cluster_on_clusters_applications_knative, unique: true }
      t.references :creator, name: :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps_with_timezone null: false
      t.string :uuid, null: false, limit: 14, primary_key: true
    end
  end
end
