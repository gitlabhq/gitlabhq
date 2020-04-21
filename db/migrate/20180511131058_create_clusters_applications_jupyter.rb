# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateClustersApplicationsJupyter < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :clusters_applications_jupyter do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.references :oauth_application, foreign_key: { on_delete: :nullify }

      t.integer :status, null: false
      t.string :version, null: false
      t.string :hostname

      t.timestamps_with_timezone null: false

      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
  # rubocop:enable Migration/PreventStrings
end
