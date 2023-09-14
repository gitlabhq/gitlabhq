# frozen_string_literal: true

class AddAuditEventsAmazonS3ConfigurationLimitToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column(:plan_limits, :audit_events_amazon_s3_configurations, :integer, default: 5, null: false)
  end
end
