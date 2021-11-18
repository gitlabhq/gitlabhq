# frozen_string_literal: true

class AddLimitsToSentrySettingsOnApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :sentry_dsn,            255
    add_text_limit :application_settings, :sentry_clientside_dsn, 255
    add_text_limit :application_settings, :sentry_environment,    255
  end

  def down
    remove_text_limit :application_settings, :sentry_dsn
    remove_text_limit :application_settings, :sentry_clientside_dsn
    remove_text_limit :application_settings, :sentry_environment
  end
end
