class AddAfterSignUpTextToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :after_sign_up_text, :text
  end
end
