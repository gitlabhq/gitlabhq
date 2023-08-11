# frozen_string_literal: true

class AddNotNullToGcpConfigName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_null :audit_events_google_cloud_logging_configurations, :name, false
  end

  def down
    change_column_null :audit_events_google_cloud_logging_configurations, :name, true
  end
end
