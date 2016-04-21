class AddSkipConfirmationEmailToApplicationSettings < ActiveRecord::Migration
  def change
    #Skip confirmation emails just for new installations
    default_value = User.count > 0 ? false : true

    add_column :application_settings, :skip_user_confirmation_email, :boolean, default: default_value
  end
end
