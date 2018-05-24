# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateClustersApplicationsJupyter < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :clusters_applications_jupyters do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.references :oauth_application

      t.integer :status, null: false
      t.string :version, null: false
      t.string :hostname

      t.text :status_reason

      t.timestamps_with_timezone null: false
    end
  end
end
