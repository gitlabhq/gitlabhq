class CreatePrometheusMetrics < ActiveRecord::Migration
  def change
    create_table :prometheus_metrics do |t|
      t.references :project, index: true, foreign_key: true
      t.string :title, null: false
      t.string :query, null: false
      t.string :y_label
      t.string :unit
      t.string :legend
      t.integer :group, null: false
      t.index :group
      t.timestamps null: false
    end
  end
end
