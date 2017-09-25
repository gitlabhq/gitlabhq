class CreateCiClusters < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :ci_clusters do |t|
      t.integer :project_id
      t.integer :owner_id
      t.integer :service_id

      # General
      t.boolean :enabled, default: true
      t.integer :creation_type # manual or on_gke

      # k8s integration specific
      t.string :project_namespace

      # Cluster details
      t.string :end_point
      t.text :ca_cert
      t.string :token
      t.string :username
      t.string :password

      # GKE
      t.string :gcp_project_id
      t.string :cluster_zone
      t.string :cluster_name

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end

    # create_table :ci_gke_clusters do |t|
    #   t.integer :ci_cluster_id
    #   t.string :gcp_project_id
    #   t.string :cluster_zone
    #   t.string :cluster_name
    # end
    # add_foreign_key :ci_gke_clusters, :ci_clusters

    # TODO: fk, index, encypt

    add_foreign_key :ci_clusters, :projects
    add_foreign_key :ci_clusters, :users, column: :owner_id
    add_foreign_key :ci_clusters, :services
  end

  def down
    drop_table :ci_clusters
  end
end
