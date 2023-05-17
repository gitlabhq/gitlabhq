# frozen_string_literal: true

class CreateAnalyticsValueStreamDashboardAggregations < Gitlab::Database::Migration[2.1]
  def change
    create_table :value_stream_dashboard_aggregations, id: false do |t|
      t.references :namespace, primary_key: true, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :last_run_at
      t.boolean :enabled, null: false, default: true

      t.index [:last_run_at, :namespace_id], where: 'enabled IS TRUE',
        name: 'index_on_value_stream_dashboard_aggregations_last_run_at_id'
    end
  end
end
