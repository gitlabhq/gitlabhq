class RemoveCiEnabledFromApplicationSettings < ActiveRecord::Migration
  def change
    remove_column :application_settings, :ci_enabled, :boolean, null: false, default: true
  end
end
