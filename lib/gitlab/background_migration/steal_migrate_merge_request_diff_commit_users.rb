# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A background migration that finished any pending
    # MigrateMergeRequestDiffCommitUsers jobs, and schedules new jobs itself.
    #
    # This migration exists so we can bypass rescheduling issues (e.g. jobs
    # getting dropped after too many retries) that may occur when
    # MigrateMergeRequestDiffCommitUsers jobs take longer than expected.
    class StealMigrateMergeRequestDiffCommitUsers
      def perform(start_id, stop_id)
        MigrateMergeRequestDiffCommitUsers.new.perform(start_id, stop_id)
        schedule_next_job
      end

      def schedule_next_job
        next_job = Database::BackgroundMigrationJob
          .for_migration_class('MigrateMergeRequestDiffCommitUsers')
          .pending
          .first

        return unless next_job

        BackgroundMigrationWorker.perform_in(
          5.minutes,
          'StealMigrateMergeRequestDiffCommitUsers',
          next_job.arguments
        )
      end
    end
  end
end
