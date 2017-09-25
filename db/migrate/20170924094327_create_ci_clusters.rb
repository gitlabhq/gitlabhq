class CreateCiClusters < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :ci_clusters do |t|
      t.integer :project_id
      t.integer :owner_id
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.boolean :enabled, default: true
      t.string :end_point
      t.text :ca_cert # Base64?
      t.string :token
      t.string :username
      t.string :password
      t.string :project_namespace
      t.integer :creation_type # manual or on_gke
    end

    # TODO: fk, index, encypt

    add_foreign_key :ci_clusters, :projects
    add_foreign_key :ci_clusters, :users, column: :owner_id
  end

  def down
    drop_table :ci_clusters
  end
end
