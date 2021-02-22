# frozen_string_literal: true

class AddInProductMarketingEmailsEnabledSetting < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :in_product_marketing_emails_enabled, :boolean, null: false, default: true
  end
end
