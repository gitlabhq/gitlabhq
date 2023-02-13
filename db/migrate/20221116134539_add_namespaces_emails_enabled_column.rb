# frozen_string_literal: true
class AddNamespacesEmailsEnabledColumn < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :emails_enabled, :boolean, default: true, null: false
  end
end
