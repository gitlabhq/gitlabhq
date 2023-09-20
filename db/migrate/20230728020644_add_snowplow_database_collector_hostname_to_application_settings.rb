# frozen_string_literal: true

class AddSnowplowDatabaseCollectorHostnameToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :snowplow_database_collector_hostname, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :snowplow_database_collector_hostname, 255
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :snowplow_database_collector_hostname, if_exists: true
    end
  end
end
