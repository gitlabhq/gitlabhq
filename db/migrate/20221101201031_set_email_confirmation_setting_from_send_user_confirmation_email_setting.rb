# frozen_string_literal: true

class SetEmailConfirmationSettingFromSendUserConfirmationEmailSetting < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    return unless ApplicationSetting.exists?
    return unless ApplicationSetting.last.send_user_confirmation_email

    ApplicationSetting.last.update(email_confirmation_setting: 2)
  end

  def down
    return unless ApplicationSetting.exists?

    ApplicationSetting.last.update(email_confirmation_setting: 0)
  end
end
