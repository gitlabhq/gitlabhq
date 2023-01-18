# frozen_string_literal: true

class AddStorageAdminControlColumnsToPlanLimits < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column(:plan_limits, :enforcement_limit, :integer, default: 0, null: false)
    add_column(:plan_limits, :notification_limit, :integer, default: 0, null: false)
    add_column(:plan_limits, :dashboard_limit_enabled_at, :datetime_with_timezone)
  end
end
