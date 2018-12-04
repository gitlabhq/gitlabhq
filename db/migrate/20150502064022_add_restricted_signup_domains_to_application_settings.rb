class AddRestrictedSignupDomainsToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :restricted_signup_domains, :text
  end
end
