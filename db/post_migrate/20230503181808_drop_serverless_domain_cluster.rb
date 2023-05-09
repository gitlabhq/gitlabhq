# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropServerlessDomainCluster < Gitlab::Database::Migration[2.1]
  def up
    drop_table :serverless_domain_cluster
  end

  # Based on original migration:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/5f7bd5b1455d87e2f1a2d1ae2c1147d51e97aa55/db/migrate/20191127030005_create_serverless_domain_cluster.rb
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  def down
    create_table :serverless_domain_cluster, id: false, primary_key: :uuid do |t|
      t.string :uuid, null: false, limit: 14, primary_key: true
      t.bigint :pages_domain_id, null: false
      t.bigint :clusters_applications_knative_id, null: false
      t.bigint :creator_id
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.text :encrypted_key
      t.string :encrypted_key_iv, limit: 255
      t.text :certificate
      t.index :clusters_applications_knative_id,
        unique: true,
        name: 'idx_serverless_domain_cluster_on_clusters_applications_knative'
      t.index :pages_domain_id, name: 'index_serverless_domain_cluster_on_pages_domain_id'
      t.index :creator_id, name: 'index_serverless_domain_cluster_on_creator_id'
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
