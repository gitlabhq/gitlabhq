# frozen_string_literal: true

class ChangeDuoSecretDetectionFpEnabledDefaultToFalse < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    change_column_default :project_settings, :duo_secret_detection_fp_enabled, from: true, to: false
  end

  def down
    change_column_default :project_settings, :duo_secret_detection_fp_enabled, from: false, to: true
  end
end
