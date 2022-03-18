# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Removing expire_at timestamps that shouldn't have
    # been written to traces on gitlab.com.
    class RemoveAllTraceExpirationDates
      include Gitlab::Database::MigrationHelpers

      BATCH_SIZE = 1_000

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

        scope :traces, -> { where(file_type: 3) }
        scope :between, -> (start_id, end_id) { where(id: start_id..end_id) }
        scope :in_targeted_timestamps, -> { where(expire_at: TARGET_TIMESTAMPS) }
      end

      def perform(start_id, end_id)
        return unless Gitlab.com?

        JobArtifact.traces
          .between(start_id, end_id)
          .in_targeted_timestamps
          .each_batch(of: BATCH_SIZE) { |batch| batch.update_all(expire_at: nil) }
      end
    end
  end
end
