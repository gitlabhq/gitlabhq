# frozen_string_literal: true

class AddNamespaceIdToAnalyticsCycleAnalyticsValueStreamSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  # rubocop:disable Rails/NotNullColumn -- NamespaceId can not have a default value
  def change
    add_column :analytics_cycle_analytics_value_stream_settings, :namespace_id, :bigint, null: false
  end
  # rubocop:enable Rails/NotNullColumn
end
