# frozen_string_literal: true

class AddAiGovernanceEnabledToProjectSettings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :project_settings, :ai_governance_enabled, :boolean, default: false, null: false
  end
end
