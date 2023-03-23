# frozen_string_literal: true

class SetEmailConfirmationSettingFromSoftEmailConfirmationFf < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  class FeatureGates < MigrationRecord
    self.table_name = 'feature_gates'
  end

  def up
    return unless FeatureGates.find_by(feature_key: 'soft_email_confirmation')&.value == 'true'

    ApplicationSetting.update_all(email_confirmation_setting: 1)
  end

  def down
    ApplicationSetting.update_all(email_confirmation_setting: 0)
  end
end
