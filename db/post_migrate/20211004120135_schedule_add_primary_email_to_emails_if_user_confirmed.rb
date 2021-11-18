# frozen_string_literal: true

class ScheduleAddPrimaryEmailToEmailsIfUserConfirmed < Gitlab::Database::Migration[1.0]
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 10_000
  MIGRATION = 'AddPrimaryEmailToEmailsIfUserConfirmed'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'users'
    self.inheritance_column = :_type_disabled
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      User,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # intentionally blank
  end
end
