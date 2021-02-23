# frozen_string_literal: true

class ScheduleSetDefaultIterationCadences < ActiveRecord::Migration[6.0]
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
    # Do nothing, rescheduling migration: 20210219102900_reschedule_set_default_iteration_cadences.rb
  end

  def down
    # Not needed
  end
end
