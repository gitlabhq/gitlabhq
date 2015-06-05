class AddSessionExpireDelayForApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :session_expire_delay, :integer, default: 10080, null: false
  end
end