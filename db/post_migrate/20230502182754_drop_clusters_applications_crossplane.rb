# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsCrossplane < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_crossplane
  end

  # Based on original migration:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/8b1637296b286a5c46e0d8fdf6da42a43a7c9986/db/migrate/20191017191341_create_clusters_applications_crossplane.rb
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  def down
    create_table :clusters_applications_crossplane, id: :integer do |t|
      t.timestamps_with_timezone null: false
      t.references :cluster, null: false, index: false
      t.integer :status, null: false
      t.string :version, null: false, limit: 255
      t.string :stack, null: false, limit: 255
      t.text :status_reason
      t.index :cluster_id, unique: true
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
