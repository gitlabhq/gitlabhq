class CreateCiClusters < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :ci_clusters do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: true
      t.references :service, foreign_key: true

      # General
      t.boolean :enabled, default: true

      # k8s integration specific
      t.string :project_namespace

      # Cluster details
      t.string :endpoint
      t.text :ca_cert
      t.string :token
      t.string :username
      t.string :password
      t.string :encrypted_password
      t.string :encrypted_password_salt
      t.string :encrypted_password_iv

      # GKE
      t.string :gcp_project_id
      t.string :cluster_zone
      t.string :cluster_name
      t.string :gcp_operation_id

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  end

  def down
    drop_table :ci_clusters
  end
end
