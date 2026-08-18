# frozen_string_literal: true

class AddSidekiqTimezoneOverrideToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    with_lock_retries do
      add_column :application_settings, :sidekiq_timezone_override, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :sidekiq_timezone_override, 255
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :sidekiq_timezone_override, if_exists: true
    end
  end
end
