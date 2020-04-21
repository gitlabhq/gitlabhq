# frozen_string_literal: true

class CreatePrometheusMetrics < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :prometheus_metrics do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.string :title, null: false
      t.string :query, null: false
      t.string :y_label
      t.string :unit
      t.string :legend
      t.integer :group, null: false, index: true
      t.timestamps_with_timezone null: false
    end
  end
  # rubocop:enable Migration/PreventStrings
end
