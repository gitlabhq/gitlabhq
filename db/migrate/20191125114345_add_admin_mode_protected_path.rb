# frozen_string_literal: true

class AddAdminModeProtectedPath < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ADMIN_MODE_ENDPOINT = '/admin/session'

  OLD_DEFAULT_PROTECTED_PATHS = [
      '/users/password',
      '/users/sign_in',
      '/api/v3/session.json',
      '/api/v3/session',
      '/api/v4/session.json',
      '/api/v4/session',
      '/users',
      '/users/confirmation',
      '/unsubscribes/',
      '/import/github/personal_access_token'
  ]

  NEW_DEFAULT_PROTECTED_PATHS = OLD_DEFAULT_PROTECTED_PATHS.dup << ADMIN_MODE_ENDPOINT

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    change_column_default :application_settings, :protected_paths, NEW_DEFAULT_PROTECTED_PATHS

    # schema allows nulls for protected_paths
    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      unless application_setting.protected_paths.include?(ADMIN_MODE_ENDPOINT)
        updated_protected_paths = application_setting.protected_paths << ADMIN_MODE_ENDPOINT

        application_setting.update(protected_paths: updated_protected_paths)
      end
    end
  end

  def down
    change_column_default :application_settings, :protected_paths, OLD_DEFAULT_PROTECTED_PATHS

    # schema allows nulls for protected_paths
    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      if application_setting.protected_paths.include?(ADMIN_MODE_ENDPOINT)
        updated_protected_paths = application_setting.protected_paths - [ADMIN_MODE_ENDPOINT]

        application_setting.update(protected_paths: updated_protected_paths)
      end
    end
  end
end
