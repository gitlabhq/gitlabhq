# frozen_string_literal: true

class AddUserSeatManagementToApplicationSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.6'

  def change
    add_column :application_settings, :user_seat_management, :jsonb, default: {}, null: false
  end
end
