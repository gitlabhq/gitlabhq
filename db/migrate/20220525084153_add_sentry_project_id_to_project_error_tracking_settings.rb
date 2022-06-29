# frozen_string_literal: true

class AddSentryProjectIdToProjectErrorTrackingSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :project_error_tracking_settings, :sentry_project_id, :bigint
  end
end
