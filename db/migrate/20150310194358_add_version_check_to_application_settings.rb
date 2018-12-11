# rubocop:disable all
class AddVersionCheckToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :version_check_enabled, :boolean, default: true
  end
end
