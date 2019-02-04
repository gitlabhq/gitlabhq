class AddDisabledOauthSignInSourcesToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :disabled_oauth_sign_in_sources, :text
  end
end
