class UpdateEpicDatesFromMilestones < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
    include EachBatch
  end

  def up
    Epic.where(start_date: nil).find_each do |epic|
      epic.update_dates
    end
  end

  def down
    # NOOP
  end
end
