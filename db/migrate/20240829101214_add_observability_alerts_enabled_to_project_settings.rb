# frozen_string_literal: true

class AddObservabilityAlertsEnabledToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    add_column :project_settings, :observability_alerts_enabled, :boolean, default: true, null: false
  end

  def down
    remove_column :project_settings, :observability_alerts_enabled
  end
end
