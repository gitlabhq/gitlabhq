# frozen_string_literal: true

class CreateAnalyticsCycleAnalyticsGroupStages < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  INDEX_PREFIX = 'index_analytics_ca_group_stages_'

  def change
    create_table :analytics_cycle_analytics_group_stages do |t|
      t.timestamps_with_timezone
      t.integer :relative_position
      t.integer :start_event_identifier, null: false
      t.integer :end_event_identifier, null: false
      t.references(:group, {
        null: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade },
        index: { name: INDEX_PREFIX + 'on_group_id' }
      })
      t.references(:start_event_label, {
        foreign_key: { to_table: :labels, on_delete: :cascade },
        index: { name: INDEX_PREFIX + 'on_start_event_label_id' }
      })
      t.references(:end_event_label, {
        foreign_key: { to_table: :labels, on_delete: :cascade },
        index: { name: INDEX_PREFIX + 'on_end_event_label_id' }
      })
      t.boolean :hidden, default: false, null: false
      t.boolean :custom, default: true, null: false
      t.string :name, null: false, limit: 255
    end

    add_index :analytics_cycle_analytics_group_stages, [:group_id, :name], unique: true, name: INDEX_PREFIX + 'on_group_id_and_name'
    add_index :analytics_cycle_analytics_group_stages, [:relative_position], name: INDEX_PREFIX + 'on_relative_position'
  end
end
