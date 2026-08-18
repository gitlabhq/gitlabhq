# frozen_string_literal: true

module Gitlab
  module Git
    class ProcessCommitWorkerPool
      JOBS_THRESHOLD = 2000
      PROCESS_COMMIT_MAX_JOBS_PER_S = 50

      def initialize(jobs_enqueued: 0)
        @jobs_enqueued = jobs_enqueued
        @scheduled_shas = {}
      end

      def get_and_increment_delay
        delay.tap { @jobs_enqueued += 1 }
      end

      def try_schedule_commit(sha, default:)
        # Only default-branch jobs run issue-closing, so a default-branch scheduling must never be dropped
        # even if the SHA was already scheduled from another branch.
        #
        # @scheduled_shas tracks a SHA's scheduling state:
        #   (no key) -> not yet scheduled
        #   false    -> scheduled from a non-default branch
        #   true     -> scheduled from a default branch (terminal state, always skip)
        previous_default = @scheduled_shas[sha]

        if previous_default.nil?
          @scheduled_shas[sha] = default
          return true
        end

        return false if previous_default || !default

        @scheduled_shas[sha] = true
        true
      end

      private

      # The number of seconds to delay ProcessCommitWorker to ensure a maximum of PROCESS_COMMIT_MAX_JOBS_PER_S jobs
      # executed per second.
      def delay
        return 0 if @jobs_enqueued < JOBS_THRESHOLD

        (@jobs_enqueued / PROCESS_COMMIT_MAX_JOBS_PER_S).seconds
      end
    end
  end
end
