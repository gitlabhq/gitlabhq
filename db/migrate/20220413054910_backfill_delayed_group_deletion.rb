# frozen_string_literal: true

class BackfillDelayedGroupDeletion < Gitlab::Database::Migration[1.0]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |application_setting|
      application_setting.update!(delayed_group_deletion: application_setting.deletion_adjourned_period > 0)
    end
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.update_all(delayed_group_deletion: true)
  end
end
