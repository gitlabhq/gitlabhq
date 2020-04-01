# frozen_string_literal: true

class SchedulePopulateUserHighestRolesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 10_000
  DELAY = 5.minutes.to_i
  DOWNTIME = false
  MIGRATION = 'PopulateUserHighestRolesTable'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include EachBatch

    scope :active, -> {
      where(state: 'active', user_type: nil, bot_type: nil)
        .where('ghost IS NOT TRUE')
    }
  end

  def up
    # We currently have ~5_300_000 users with the state active on GitLab.com.
    # This means it'll schedule ~530 jobs (10k Users each) with a 5 minutes gap,
    # so this should take ~44 hours for all background migrations to complete.
    User.active.each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(id)'), Arel.sql('MAX(id)')).first
      delay = index * DELAY

      migrate_in(delay.seconds, MIGRATION, [*range])
    end
  end

  def down
    # nothing
  end
end
