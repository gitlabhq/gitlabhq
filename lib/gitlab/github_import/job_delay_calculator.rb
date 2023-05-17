# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Used to calculate delay to spread sidekiq jobs on fetching records during import
    # and upon job reschedule when the rate limit is reached
    module JobDelayCalculator
      # Default batch settings for parallel import (can be redefined in Importer/Worker classes)
      def parallel_import_batch
        { size: 1000, delay: 1.minute }
      end

      private

      def calculate_job_delay(job_index)
        multiplier = (job_index / parallel_import_batch[:size])

        (multiplier * parallel_import_batch[:delay]) + 1.second
      end
    end
  end
end
