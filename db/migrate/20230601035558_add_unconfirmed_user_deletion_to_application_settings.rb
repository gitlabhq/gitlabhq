# frozen_string_literal: true

class AddUnconfirmedUserDeletionToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :delete_unconfirmed_users, :boolean, default: false, null: false
    add_column :application_settings, :unconfirmed_users_delete_after_days, :integer, default: 7, null: false
  end
end
