class AddAfterSignOutPathForApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :after_sign_out_path, :string
  end
end