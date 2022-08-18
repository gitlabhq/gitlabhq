# frozen_string_literal: true
class AddDeactivateDormantUserTimeSetting < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :deactivate_dormant_users_period, :integer, default: 90, null: false
  end
end
