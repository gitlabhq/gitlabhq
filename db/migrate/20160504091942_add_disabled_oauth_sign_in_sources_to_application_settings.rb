class AddDisabledOauthSignInSourcesToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :disabled_oauth_sign_in_sources, :text
  end
end
