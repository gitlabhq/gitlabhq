# frozen_string_literal: true

class AddNotificationLevelToCiNamespaceMonthlyUsages < Gitlab::Database::Migration[1.0]
  def change
    add_column :ci_namespace_monthly_usages, :notification_level, :integer, limit: 2, default: 100, null: false
  end
end
