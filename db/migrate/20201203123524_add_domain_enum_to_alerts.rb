# frozen_string_literal: true

class AddDomainEnumToAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :alert_management_alerts, :domain, :integer, limit: 2, default: 0
    end
  end

  def down
    with_lock_retries do
      remove_column :alert_management_alerts, :domain, :integer, limit: 2
    end
  end
end
