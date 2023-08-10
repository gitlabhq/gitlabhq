# frozen_string_literal: true

class AddSentryClientsideTracesSampleRate < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :sentry_clientside_traces_sample_rate,
      :float, default: 0, null: false, if_not_exists: true
  end
end
