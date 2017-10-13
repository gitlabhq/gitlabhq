class CreateGcpClusters < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :clusters do |t|
      t.references :user, foreign_key: { on_delete: :nullify }

      t.boolean :enabled, default: true

      t.integer :provider_type, null: false
      t.integer :platform_type, null: false

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end

    create_table :cluster_projects do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  
    create_table :cluster_kubernetes_platforms do |t|
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.string :api_url
      t.text :ca_cert

      t.string :namespace

      t.string :username
      t.text :encrypted_password
      t.string :encrypted_password_iv

      t.text :encrypted_token
      t.string :encrypted_token_iv

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end

    create_table :cluster_gcp_providers do |t|
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.integer :status
      t.text :status_reason

      t.string :project_id, null: false
      t.string :cluster_zone, null: false
      t.string :cluster_name, null: false
      t.integer :cluster_size, null: false
      t.string :machine_type
      t.string :operation_id

      t.string :endpoint

      t.text :encrypted_access_token
      t.string :encrypted_access_token_iv

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  end
end
