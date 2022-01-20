# frozen_string_literal: true

class UpdateApplicationSettingsProtectedPaths < Gitlab::Database::Migration[1.0]
  REMOVE_PROTECTED_PATHS = [
    '/oauth/authorize',
    '/oauth/token'
  ].freeze

  NEW_DEFAULT_PROTECTED_PATHS = [
    '/users/password',
    '/users/sign_in',
    '/api/v3/session.json',
    '/api/v3/session',
    '/api/v4/session.json',
    '/api/v4/session',
    '/users',
    '/users/confirmation',
    '/unsubscribes/',
    '/import/github/personal_access_token',
    '/admin/session'
  ].freeze

  OLD_DEFAULT_PROTECTED_PATHS = (NEW_DEFAULT_PROTECTED_PATHS + REMOVE_PROTECTED_PATHS).freeze

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    change_column_default(:application_settings, :protected_paths, NEW_DEFAULT_PROTECTED_PATHS)

    ApplicationSetting.reset_column_information

    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      paths_to_remove = application_setting.protected_paths & REMOVE_PROTECTED_PATHS

      next if paths_to_remove.empty?

      updated_protected_paths = application_setting.protected_paths - paths_to_remove
      application_setting.update!(protected_paths: updated_protected_paths)
    end
  end

  def down
    change_column_default(:application_settings, :protected_paths, OLD_DEFAULT_PROTECTED_PATHS)

    ApplicationSetting.reset_column_information

    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      paths_to_add = REMOVE_PROTECTED_PATHS - application_setting.protected_paths

      next if paths_to_add.empty?

      updated_protected_paths = application_setting.protected_paths + paths_to_add
      application_setting.update!(protected_paths: updated_protected_paths)
    end
  end
end
