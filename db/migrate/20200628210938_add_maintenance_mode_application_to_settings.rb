# frozen_string_literal: true

class AddMaintenanceModeApplicationToSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:application_settings, :maintenance_mode)
      change_table :application_settings do |t|
        t.boolean :maintenance_mode, default: false, null: false
        t.text :maintenance_mode_message
      end
    end

    add_text_limit(:application_settings, :maintenance_mode_message, 255)
  end

  def down
    if column_exists?(:application_settings, :maintenance_mode)
      remove_column :application_settings, :maintenance_mode
    end

    if column_exists?(:application_settings, :maintenance_mode_message)
      remove_column :application_settings, :maintenance_mode_message
    end
  end
end
