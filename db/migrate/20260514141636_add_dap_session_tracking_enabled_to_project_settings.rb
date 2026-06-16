# frozen_string_literal: true

class AddDapSessionTrackingEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :project_settings, :dap_session_tracking_enabled, :boolean, default: false, null: false
  end
end
