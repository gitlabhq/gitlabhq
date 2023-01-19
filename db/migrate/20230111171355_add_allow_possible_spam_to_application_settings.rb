# frozen_string_literal: true

class AddAllowPossibleSpamToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :allow_possible_spam, :boolean, default: false, null: false
  end
end
