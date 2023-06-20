# frozen_string_literal: true

class AddAllowAccountDeletionToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :allow_account_deletion, :boolean, default: true, null: false
  end
end
