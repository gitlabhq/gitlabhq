# frozen_string_literal: true

class AddServiceDeskEmailRateLimitsToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :plan_limits, :service_desk_outbound_emails_per_hour, :integer, default: 0, null: false
    add_column :plan_limits, :service_desk_outbound_emails_per_day, :integer, default: 0, null: false
  end
end
