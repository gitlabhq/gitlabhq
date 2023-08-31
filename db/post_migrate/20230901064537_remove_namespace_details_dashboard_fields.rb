# frozen_string_literal: true

class RemoveNamespaceDetailsDashboardFields < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :namespace_details, :dashboard_notification_at, :datetime_with_timezone
    remove_column :namespace_details, :dashboard_enforcement_at, :datetime_with_timezone
  end
end
