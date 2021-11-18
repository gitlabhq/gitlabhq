# frozen_string_literal: true

class AddSentrySettingsToApplicationSettings < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :application_settings, :sentry_enabled, :boolean, default: false, null: false
    add_column :application_settings, :sentry_dsn,            :text
    add_column :application_settings, :sentry_clientside_dsn, :text
    add_column :application_settings, :sentry_environment,    :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
