class AddAfterSignUpTextToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :after_sign_up_text, :text
  end
end
