# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        # This strategy takes a lock before scheduling the job in a queue and
        # removes the lock before the job starts allowing a new job to be queued
        # while a job is still executing.
        class UntilExecuting < DeduplicatesWhenScheduling
          override :perform
          def perform(job)
            super
            duplicate_job.delete!

            yield
          end
        end
      end
    end
  end
end
