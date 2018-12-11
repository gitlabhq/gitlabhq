class AddRunnersRegistrationTokenToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :runners_registration_token, :string
  end
end
