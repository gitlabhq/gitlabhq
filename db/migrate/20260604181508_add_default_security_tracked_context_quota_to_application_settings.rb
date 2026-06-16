# frozen_string_literal: true

class AddDefaultSecurityTrackedContextQuotaToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :application_settings, :default_security_tracked_context_quota, :integer, default: 2, null: true
  end
end
