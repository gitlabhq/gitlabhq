# frozen_string_literal: true

class IndexAnalyticsCycleAnalyticsValueStreamSettingsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_analytics_cycle_analytics_value_stream_settings_on_namesp'

  def up
    add_concurrent_index :analytics_cycle_analytics_value_stream_settings, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :analytics_cycle_analytics_value_stream_settings, INDEX_NAME
  end
end
