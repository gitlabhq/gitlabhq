# frozen_string_literal: true

class RenameUserEmailLookupLimitSettingToSearchSettingsCleanup < Gitlab::Database::Migration[1.0]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = :application_settings
  end

  def up
    ApplicationSetting.update_all 'search_rate_limit=user_email_lookup_limit'
  end

  def down
    ApplicationSetting.update_all 'user_email_lookup_limit=search_rate_limit'
  end
end
