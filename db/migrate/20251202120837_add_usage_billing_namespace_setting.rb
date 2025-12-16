# frozen_string_literal: true

class AddUsageBillingNamespaceSetting < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :namespace_settings, :usage_billing, :jsonb, default: {}, null: false
  end
end
