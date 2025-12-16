# frozen_string_literal: true

class AddUsageBillingApplicationSetting < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :application_settings, :usage_billing, :jsonb, default: {}, null: false
  end
end
