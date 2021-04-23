# frozen_string_literal: true

class AddDeactivateDormantUsersToApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :application_settings, :deactivate_dormant_users, :boolean, default: false, null: false
  end
end
