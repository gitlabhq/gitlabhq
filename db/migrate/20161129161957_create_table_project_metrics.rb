# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateTableProjectMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :project_metrics do |t|
      t.integer :project_id, null: false
      t.integer :shared_runners_minutes, default: 0, null: false
    end

    add_foreign_key :project_metrics, :projects, column: :project_id, on_delete: :cascade
  end
end
