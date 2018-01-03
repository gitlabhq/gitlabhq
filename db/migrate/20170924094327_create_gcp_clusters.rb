class CreateGcpClusters < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :gcp_clusters do |t|
      # Order columns by best align scheme
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.references :service, foreign_key: { on_delete: :nullify }
      t.integer :status
      t.integer :gcp_cluster_size, null: false

      # Timestamps
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      # Enable/disable
      t.boolean :enabled, default: true

      # General
      t.text :status_reason

      # k8s integration specific
      t.string :project_namespace

      # Cluster details
      t.string :endpoint
      t.text :ca_cert
      t.text :encrypted_kubernetes_token
      t.string :encrypted_kubernetes_token_iv
      t.string :username
      t.text :encrypted_password
      t.string :encrypted_password_iv

      # GKE
      t.string :gcp_project_id, null: false
      t.string :gcp_cluster_zone, null: false
      t.string :gcp_cluster_name, null: false
      t.string :gcp_machine_type
      t.string :gcp_operation_id
      t.text :encrypted_gcp_token
      t.string :encrypted_gcp_token_iv
    end
  end
end
