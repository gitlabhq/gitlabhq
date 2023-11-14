# frozen_string_literal: true

class RemoveApplicationSettingsMarketingEmailsEnabledColumn < Gitlab::Database::Migration[2.1]
  def up
    remove_column :application_settings, :in_product_marketing_emails_enabled
  end

  def down
    add_column :application_settings, :in_product_marketing_emails_enabled, :boolean, default: true, null: false
  end
end
