# frozen_string_literal: true

class AddTrackingColumnsToNamespaceLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column :namespace_limits, :pre_enforcement_notification_at, :datetime_with_timezone
    add_column :namespace_limits, :first_enforced_at, :datetime_with_timezone
  end
end
