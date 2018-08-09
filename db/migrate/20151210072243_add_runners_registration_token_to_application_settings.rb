class AddRunnersRegistrationTokenToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :runners_registration_token, :string
  end
end
