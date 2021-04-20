# frozen_string_literal: true

class AddAdminModeToApplicationSetting < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :admin_mode, :boolean, default: false, null: false
  end
end
