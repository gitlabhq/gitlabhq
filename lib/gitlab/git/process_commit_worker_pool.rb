# frozen_string_literal: true

module Gitlab
  module Git
    class ProcessCommitWorkerPool
      JOBS_THRESHOLD = 2000
      PROCESS_COMMIT_MAX_JOBS_PER_S = 50

      def initialize(jobs_enqueued: 0)
        @jobs_enqueued = jobs_enqueued
      end

      def get_and_increment_delay
        delay.tap { @jobs_enqueued += 1 }
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
