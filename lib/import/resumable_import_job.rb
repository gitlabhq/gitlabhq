# frozen_string_literal: true

module Import
  module ResumableImportJob
    extend ActiveSupport::Concern

    # Maximum number of retries after interruption for resumable import jobs
    # This higher limit is safe for jobs that can resume exactly where they left off
    MAX_RETRIES_AFTER_INTERRUPTION = 20

    class_methods do
      # We can increase the number of times a worker is retried
      # after being interrupted if the importer it executes can restart exactly
      # from where it left off.
      #
      # It is not safe to call this method if the importer loops over its data from
      # the beginning when restarted, even if it skips data that is already imported
      # inside the loop, as there is a possibility the importer will never reach
      # the end of the loop.
      #
      # Examples of stage workers that call this method are ones that execute services that:
      #
      # - Continue paging an endpoint from where it left off:
      #   https://gitlab.com/gitlab-org/gitlab/-/blob/487521cc/lib/gitlab/github_import/parallel_scheduling.rb#L114-117
      # - Continue their loop from where it left off:
      #   https://gitlab.com/gitlab-org/gitlab/-/blob/024235ec/lib/gitlab/github_import/importer/pull_requests/review_requests_importer.rb#L15
      def resumes_work_when_interrupted!
        sidekiq_options max_retries_after_interruption: MAX_RETRIES_AFTER_INTERRUPTION
      end
    end
  end
end
