# frozen_string_literal: true

class FixTotalStageInVsa < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TOTAL_STAGE = 'Total'

  class GroupStage < ActiveRecord::Base
    include EachBatch

    self.table_name = 'analytics_cycle_analytics_group_stages'
  end

  def up
    GroupStage.reset_column_information

    GroupStage.each_batch(of: 100) do |relation|
      relation.where(name: TOTAL_STAGE, custom: false).update_all(custom: true)
    end
  end

  def down
    # no-op
  end
end
