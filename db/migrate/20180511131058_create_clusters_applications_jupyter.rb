# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateClustersApplicationsJupyter < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :clusters_applications_jupyter do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.references :oauth_application, foreign_key: { on_delete: :nullify }

      t.integer :status, null: false
      t.string :version, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.string :hostname # rubocop:disable Migration/AddLimitToStringColumns

      t.timestamps_with_timezone null: false

      t.text :status_reason
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
