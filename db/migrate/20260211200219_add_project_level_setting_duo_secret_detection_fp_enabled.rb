# frozen_string_literal: true

class AddProjectLevelSettingDuoSecretDetectionFpEnabled < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :project_settings, :duo_secret_detection_fp_enabled, :boolean, default: true, null: false
  end
end
