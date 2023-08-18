# frozen_string_literal: true

class AddSentryClientsideTracesSampleRateConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_app_settings_sentry_clientside_traces_sample_rate_range'

  def up
    add_check_constraint :application_settings,
      'sentry_clientside_traces_sample_rate >= 0 AND sentry_clientside_traces_sample_rate <= 1',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
