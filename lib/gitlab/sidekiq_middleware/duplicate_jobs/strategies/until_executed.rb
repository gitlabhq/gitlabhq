# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        # This strategy takes a lock before scheduling the job in a queue and
        # removes the lock after the job has executed preventing a new job to be queued
        # while a job is still executing.
        class UntilExecuted < DeduplicatesWhenScheduling
          override :perform
          def perform(job)
            job_deleted = false

            super

            yield

            should_reschedule = duplicate_job.should_reschedule?
            # Deleting before rescheduling to make sure we don't deduplicate again.
            duplicate_job.delete!
            job_deleted = true
            duplicate_job.reschedule if should_reschedule
          ensure
            duplicate_job.delete! unless job_deleted
          end
        end
      end
    end
  end
end
