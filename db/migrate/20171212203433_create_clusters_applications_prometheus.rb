class CreateClustersApplicationsPrometheus < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :clusters_applications_prometheus do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }

      t.integer :status, null: false
      t.string :version, null: false

      t.text :status_reason

      t.timestamps_with_timezone null: false
    end
  end
end
