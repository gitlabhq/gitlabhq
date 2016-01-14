class RemoveInfluxdbCredentials < ActiveRecord::Migration
  def change
    remove_column :application_settings, :metrics_username, :string
    remove_column :application_settings, :metrics_password, :string
  end
end
