class CreatePrometheusMetrics < ActiveRecord::Migration
  def change
    create_table :prometheus_metrics do |t|
      t.references :project, index: true, foreign_key: true
      t.string :title
      t.string :query
      t.string :y_label
      t.string :unit
      t.string :legend

      t.timestamps null: false
    end
  end
end
