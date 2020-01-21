# frozen_string_literal: true

class FixMaxPagesSize < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  MAX_SIZE = 1.terabyte / 1.megabyte

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
    self.inheritance_column = :_type_disabled
  end

  def up
    table = ApplicationSetting.arel_table
    ApplicationSetting.where(table[:max_pages_size].gt(MAX_SIZE)).update_all(max_pages_size: MAX_SIZE)
  end

  def down
    # no-op
  end
end
