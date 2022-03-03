# frozen_string_literal: true

class ScheduleTraceExpiryRemoval < Gitlab::Database::Migration[1.0]
  MIGRATION = 'RemoveAllTraceExpirationDates'
  BATCH_SIZE = 100_000
  DELAY_INTERVAL = 4.minutes

  disable_ddl_transaction!

  # Stubbed class to connect to the CI database
  # connects_to has to be called in abstract classes.
  class MultiDbAdaptableClass < ActiveRecord::Base
    self.abstract_class = true

    if Gitlab::Database.has_config?(:ci)
      connects_to database: { writing: :ci, reading: :ci }
    end
  end

  # Stubbed class to access the ci_job_artifacts table
  class JobArtifact < MultiDbAdaptableClass
    include EachBatch

    self.table_name = 'ci_job_artifacts'

    TARGET_TIMESTAMPS = [
      Date.new(2021, 04, 22).midnight.utc,
      Date.new(2021, 05, 22).midnight.utc,
      Date.new(2021, 06, 22).midnight.utc,
      Date.new(2022, 01, 22).midnight.utc,
      Date.new(2022, 02, 22).midnight.utc,
      Date.new(2022, 03, 22).midnight.utc,
      Date.new(2022, 04, 22).midnight.utc
    ].freeze

    scope :in_targeted_timestamps, -> { where(expire_at: TARGET_TIMESTAMPS) }
    scope :traces, -> { where(file_type: 3) }
  end

  def up
    return unless Gitlab.com?

    queue_background_migration_jobs_by_range_at_intervals(
      JobArtifact.traces.in_targeted_timestamps,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
