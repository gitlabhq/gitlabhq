# frozen_string_literal: true

class DisableAllowRunnerRegistrationForSelfManaged < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class TmpApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    application_setting = TmpApplicationSetting.last
    return unless should_run?(application_setting)

    new_attributes = { allow_runner_registration_token: false }

    return TmpApplicationSetting.insert(new_attributes) unless application_setting

    application_setting.update!(new_attributes)
  end

  def down
    # no-op, since we might be re-enabling a setting that had been disabled in the first place by the admin before
    # the migration
  end

  private

  def should_run?(application_setting)
    return true if application_setting&.gitlab_dedicated_instance

    !Gitlab.com?
  end
end
