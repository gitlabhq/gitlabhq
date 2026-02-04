# frozen_string_literal: true

class AddDuoSastVrWorkflowEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :project_settings, :duo_sast_vr_workflow_enabled, :boolean, default: false, null: false
  end
end
