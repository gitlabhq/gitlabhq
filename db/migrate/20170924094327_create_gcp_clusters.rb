class CreateGcpClusters < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gcp_clusters do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: true
      t.references :service, foreign_key: true

      # General
      t.boolean :enabled, default: true
      t.integer :status
      t.string :status_reason

      # k8s integration specific
      t.string :project_namespace

      # Cluster details
      t.string :endpoint
      t.text :ca_cert
      t.string :encrypted_kubernetes_token
      t.string :encrypted_kubernetes_token_salt
      t.string :encrypted_kubernetes_token_iv
      t.string :username
      t.string :encrypted_password
      t.string :encrypted_password_salt
      t.string :encrypted_password_iv

      # GKE
      t.string :gcp_project_id, null: false
      t.string :cluster_zone, null: false
      t.string :cluster_name, null: false
      t.integer :cluster_size, null: false
      t.string :machine_type
      t.string :gcp_operation_id
      t.string :encrypted_gcp_token
      t.string :encrypted_gcp_token_salt
      t.string :encrypted_gcp_token_iv

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  end
end
