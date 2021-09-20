# frozen_string_literal: true

class RemoveSeatLinkEnabledFromApplicationSettings < ActiveRecord::Migration[6.1]
  def up
    remove_column :application_settings, :seat_link_enabled
  end

  def down
    add_column :application_settings, :seat_link_enabled, :boolean, null: false, default: true
  end
end
