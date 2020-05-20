# frozen_string_literal: true

class RemoveAdditionalApplicationSettingsRows < ActiveRecord::Migration[6.0]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    return if ApplicationSetting.count == 1

    execute "DELETE from application_settings WHERE id NOT IN (SELECT MAX(id) FROM application_settings);"
  end

  def down
    # no changes
  end
end
