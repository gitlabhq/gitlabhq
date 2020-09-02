# frozen_string_literal: true

class AddOAuthPathsToProtectedPaths < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ADD_PROTECTED_PATHS = [
    '/oauth/authorize',
    '/oauth/token'
  ].freeze

  EXISTING_DEFAULT_PROTECTED_PATHS = [
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

  NEW_DEFAULT_PROTECTED_PATHS = (EXISTING_DEFAULT_PROTECTED_PATHS + ADD_PROTECTED_PATHS).freeze

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    change_column_default :application_settings, :protected_paths, NEW_DEFAULT_PROTECTED_PATHS

    ApplicationSetting.reset_column_information

    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      missing_paths = ADD_PROTECTED_PATHS - application_setting.protected_paths

      next if missing_paths.empty?

      updated_protected_paths = application_setting.protected_paths + missing_paths
      application_setting.update!(protected_paths: updated_protected_paths)
    end
  end

  def down
    change_column_default :application_settings, :protected_paths, EXISTING_DEFAULT_PROTECTED_PATHS

    ApplicationSetting.reset_column_information

    ApplicationSetting.where.not(protected_paths: nil).each do |application_setting|
      paths_to_remove = application_setting.protected_paths - EXISTING_DEFAULT_PROTECTED_PATHS

      next if paths_to_remove.empty?

      updated_protected_paths = application_setting.protected_paths - paths_to_remove
      application_setting.update!(protected_paths: updated_protected_paths)
    end
  end
end
