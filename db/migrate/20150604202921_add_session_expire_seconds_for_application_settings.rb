class AddSessionExpireSecondsForApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :session_expire_seconds, :integer, default: 604800, null: false
  end
end