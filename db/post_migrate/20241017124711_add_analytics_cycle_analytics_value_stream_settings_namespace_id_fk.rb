# frozen_string_literal: true

class AddAnalyticsCycleAnalyticsValueStreamSettingsNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :analytics_cycle_analytics_value_stream_settings, :namespaces, column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :analytics_cycle_analytics_value_stream_settings, column: :namespace_id
    end
  end
end
