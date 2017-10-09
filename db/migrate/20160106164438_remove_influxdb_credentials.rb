# rubocop:disable all
class RemoveInfluxdbCredentials < ActiveRecord::Migration[4.2]
  def change
    remove_column :application_settings, :metrics_username, :string
    remove_column :application_settings, :metrics_password, :string
  end
end
