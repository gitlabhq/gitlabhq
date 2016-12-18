class CreateTableProjectMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_metrics do |t|
      t.integer :project_id, null: false
      t.integer :shared_runners_minutes, default: 0, null: false
      t.timestamp :shared_runners_minutes_last_reset
    end

    add_foreign_key :project_metrics, :projects, on_delete: :cascade
  end
end
