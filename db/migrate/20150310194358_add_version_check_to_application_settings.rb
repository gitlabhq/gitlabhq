class AddVersionCheckToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :version_check_enabled, :boolean, default: true
  end
end
