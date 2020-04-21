# frozen_string_literal: true

class CreateOperationsStrategiesTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :operations_strategies do |t|
      t.references :feature_flag, index: true, null: false, foreign_key: { to_table: :operations_feature_flags, on_delete: :cascade }
      t.string :name, null: false, limit: 255
      t.jsonb :parameters, null: false, default: {}
    end
  end
  # rubocop:enable Migration/PreventStrings
end
