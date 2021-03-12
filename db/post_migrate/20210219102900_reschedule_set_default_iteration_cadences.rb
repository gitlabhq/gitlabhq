# frozen_string_literal: true

class RescheduleSetDefaultIterationCadences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  DELAY_INTERVAL = 2.minutes.to_i
  MIGRATION_CLASS = 'SetDefaultIterationCadences'

  class Iteration < ActiveRecord::Base # rubocop:disable Style/Documentation
    include EachBatch

    self.table_name = 'sprints'
  end

  disable_ddl_transaction!

  def up
    Iteration.select(:group_id).distinct.each_batch(of: BATCH_SIZE, column: :group_id) do |batch, index|
      group_ids = batch.pluck(:group_id)

      migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, group_ids)
    end
  end

  def down
    # Not needed
  end
end
