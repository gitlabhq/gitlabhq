# frozen_string_literal: true

class BackfillDefaultBranchProtectionApplicationSetting < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  BRANCH_PROTECTION = [
    { "allow_force_push" => true,
      "allowed_to_merge" => [{ "access_level" => 30 }],
      "allowed_to_push" => [{ "access_level" => 30 }] },
    { "allow_force_push" => false,
      "allowed_to_merge" => [{ "access_level" => 30 }],
      "allowed_to_push" => [{ "access_level" => 30 }] },
    { "allow_force_push" => false,
      "allowed_to_merge" => [{ "access_level" => 40 }],
      "allowed_to_push" => [{ "access_level" => 40 }] },
    { "allow_force_push" => true,
      "allowed_to_merge" => [{ "access_level" => 30 }],
      "allowed_to_push" => [{ "access_level" => 40 }] },
    { "allow_force_push" => true,
      "allowed_to_merge" => [{ "access_level" => 30 }],
      "allowed_to_push" => [{ "access_level" => 40 }],
      "developer_can_initial_push" => true }
  ]

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |application_setting|
      level = application_setting.default_branch_protection.to_i
      protection_hash = BRANCH_PROTECTION[level]
      application_setting.update!(default_branch_protection_defaults: protection_hash)
    end
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.update_all(default_branch_protection_defaults: {})
  end
end
