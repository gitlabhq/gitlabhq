# rubocop:disable all
class AddAfterSignOutPathForApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :after_sign_out_path, :string
  end
end