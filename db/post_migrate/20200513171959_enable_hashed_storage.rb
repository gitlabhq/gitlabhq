# frozen_string_literal: true

class EnableHashedStorage < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.update_all(hashed_storage_enabled: true)
  end

  def down
    # in 13.0 we are forcing hashed storage to always be enabled for new projects
  end
end
