# frozen_string_literal: true

class AddColumnsProjectErrorTrackingSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :project_error_tracking_settings, :project_name, :string
    add_column :project_error_tracking_settings, :organization_name, :string

    change_column_default :project_error_tracking_settings, :enabled, from: true, to: false

    change_column_null :project_error_tracking_settings, :api_url, true
  end
  # rubocop:enable Migration/PreventStrings
end
