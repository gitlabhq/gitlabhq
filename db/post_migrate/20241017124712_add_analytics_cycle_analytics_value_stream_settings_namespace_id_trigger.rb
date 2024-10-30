# frozen_string_literal: true

class AddAnalyticsCycleAnalyticsValueStreamSettingsNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    install_sharding_key_assignment_trigger(
      table: :analytics_cycle_analytics_value_stream_settings,
      sharding_key: :namespace_id,
      parent_table: :analytics_cycle_analytics_group_value_streams,
      parent_sharding_key: :group_id,
      foreign_key: :value_stream_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :analytics_cycle_analytics_value_stream_settings,
      sharding_key: :namespace_id,
      parent_table: :analytics_cycle_analytics_group_value_streams,
      parent_sharding_key: :group_id,
      foreign_key: :value_stream_id
    )
  end
end
