# frozen_string_literal: true

class AddDuoRemoteFlowsEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :project_settings, :duo_remote_flows_enabled, :boolean, default: false, null: false
  end
end
