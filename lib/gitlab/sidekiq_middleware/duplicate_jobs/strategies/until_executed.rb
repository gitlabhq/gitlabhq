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

            # early return since not reschedulable. ensure block to handle cleanup.
            return unless duplicate_job.reschedulable?

            duplicate_job.delete!
            job_deleted = true
            duplicate_job.reschedule if duplicate_job.check_and_del_reschedule_signal
          ensure
            duplicate_job.delete! unless job_deleted
          end
        end
      end
    end
  end
end
