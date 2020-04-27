# frozen_string_literal: true

class CreateOperationsStrategiesUserLists < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :operations_strategies_user_lists do |t|
      t.references :strategy, index: false, foreign_key: { on_delete: :cascade, to_table: :operations_strategies }, null: false
      t.references :user_list, index: true, foreign_key: { on_delete: :cascade, to_table: :operations_user_lists }, null: false

      t.index [:strategy_id, :user_list_id], unique: true, name: :index_ops_strategies_user_lists_on_strategy_id_and_user_list_id
    end
  end
end
