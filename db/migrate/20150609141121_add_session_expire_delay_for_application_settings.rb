class AddSessionExpireDelayForApplicationSettings < ActiveRecord::Migration
  def change
    unless column_exists?(:application_settings, :session_expire_delay)
      add_column :application_settings, :session_expire_delay, :integer, default: 10080, null: false
    end
  end
end
