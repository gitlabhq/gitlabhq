# frozen_string_literal: true

class CreateNamespaceAggregationSchedules < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    create_table :namespace_aggregation_schedules, id: false, primary_key: :namespace_id do |t|
      t.integer :namespace_id, null: false, primary_key: true

      t.index :namespace_id, unique: true
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :cascade
    end
  end
end
