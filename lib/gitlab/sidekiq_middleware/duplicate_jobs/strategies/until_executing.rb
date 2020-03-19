# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        # This strategy takes a lock before scheduling the job in a queue and
        # removes the lock before the job starts allowing a new job to be queued
        # while a job is still executing.
        class UntilExecuting
          def initialize(duplicate_job)
            @duplicate_job = duplicate_job
          end

          def schedule(job)
            if duplicate_job.check! && duplicate_job.duplicate?
              job['duplicate-of'] = duplicate_job.existing_jid
            end

            if duplicate_job.droppable?
              Gitlab::SidekiqLogging::DeduplicationLogger.instance.log(job, "dropped until executing")
              return false
            end

            yield
          end

          def perform(_job)
            duplicate_job.delete!

            yield
          end

          private

          attr_reader :duplicate_job
        end
      end
    end
  end
end
