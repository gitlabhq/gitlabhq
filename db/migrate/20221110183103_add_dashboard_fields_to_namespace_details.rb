# frozen_string_literal: true

class AddDashboardFieldsToNamespaceDetails < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_details, :dashboard_notification_at, :datetime_with_timezone
    add_column :namespace_details, :dashboard_enforcement_at, :datetime_with_timezone
  end
end
