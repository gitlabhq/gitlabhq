# frozen_string_literal: true

class CreateOperationsScopesTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :operations_scopes do |t|
      t.references :strategy, null: false, index: false, foreign_key: { to_table: :operations_strategies, on_delete: :cascade }
      t.string :environment_scope, null: false, limit: 255
    end

    add_index :operations_scopes, [:strategy_id, :environment_scope], unique: true
  end
  # rubocop:enable Migration/PreventStrings
end
