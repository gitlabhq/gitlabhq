class CreatePrometheusAlerts < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :prometheus_alerts do |t|
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.float :threshold, null: false
      t.integer :operator, null: false
      t.references :environment, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :prometheus_metric, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
    end
  end

  def down
    remove_foreign_key :prometheus_alerts, column: :project_id
    drop_table :prometheus_alerts
  end
end
