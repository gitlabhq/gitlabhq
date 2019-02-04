class AllowDomainVerificationToBeDisabled < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :application_settings, :pages_domain_verification_enabled, :boolean, default: true, null: false
  end
end
