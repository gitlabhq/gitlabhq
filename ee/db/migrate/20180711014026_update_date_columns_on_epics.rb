# frozen_string_literal: true

class UpdateDateColumnsOnEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
    include EachBatch
  end

  def up
    Epic.where.not(start_date: nil).each_batch do |batch|
      batch.update_all('start_date_is_fixed = true, start_date_fixed = start_date')
    end

    Epic.where.not(end_date: nil).each_batch do |batch|
      batch.update_all('due_date_is_fixed = true, due_date_fixed = end_date')
    end
  end

  def down
    # NOOP
  end
end
