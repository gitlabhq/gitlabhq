class AddCiEnabledToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :ci_enabled, :boolean, null: false, default: true
  end
end
