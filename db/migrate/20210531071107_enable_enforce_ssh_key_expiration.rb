# frozen_string_literal: true

class EnableEnforceSshKeyExpiration < ActiveRecord::Migration[6.0]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.where.not(enforce_ssh_key_expiration: true).each do |application_setting|
      application_setting.update!(enforce_ssh_key_expiration: true)
    end
  end
end
