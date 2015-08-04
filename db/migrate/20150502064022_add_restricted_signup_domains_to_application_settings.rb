class AddRestrictedSignupDomainsToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :restricted_signup_domains, :text
  end
end
