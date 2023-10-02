# frozen_string_literal: true

class CreateValueStreamAnalyticsSettings < Gitlab::Database::Migration[2.1]
  def change
    create_table :analytics_cycle_analytics_value_stream_settings, id: false do |t|
      t.references(
        :value_stream,
        primary_key: true,
        default: nil,
        type: :bigint,
        index: false,
        foreign_key: {
          to_table: :analytics_cycle_analytics_group_value_streams,
          column: :analytics_cycle_analytics_group_value_stream_id,
          on_delete: :cascade
        }
      )

      t.bigint :project_ids_filter, array: true, default: []
      t.check_constraint 'CARDINALITY(project_ids_filter) <= 100'
    end
  end
end
