# frozen_string_literal: true

class ChangeDuoSastFpDetectionEnabledDefaultToFalse < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    change_column_default(:project_settings, :duo_sast_fp_detection_enabled, from: true, to: false)
  end
end
