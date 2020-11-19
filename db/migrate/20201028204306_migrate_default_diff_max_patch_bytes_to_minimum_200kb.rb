# frozen_string_literal: true

class MigrateDefaultDiffMaxPatchBytesToMinimum200kb < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  MAX_SIZE = 200.kilobytes

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    table = ApplicationSetting.arel_table
    ApplicationSetting.where(table[:diff_max_patch_bytes].lt(MAX_SIZE)).update_all(diff_max_patch_bytes: MAX_SIZE)
  end

  def down
    table = ApplicationSetting.arel_table
    ApplicationSetting.where(table[:diff_max_patch_bytes].eq(MAX_SIZE)).update_all(diff_max_patch_bytes: 100.kilobytes)
  end
end
