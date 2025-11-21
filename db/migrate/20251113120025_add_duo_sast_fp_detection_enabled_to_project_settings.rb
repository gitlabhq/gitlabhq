# frozen_string_literal: true

class AddDuoSastFpDetectionEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :project_settings, :duo_sast_fp_detection_enabled, :boolean, default: true, null: false
  end
end
