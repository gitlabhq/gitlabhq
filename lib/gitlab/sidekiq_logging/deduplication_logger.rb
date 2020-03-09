# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class DeduplicationLogger
      include Singleton
      include LogsJobs

      def log(job, deduplication_type)
        payload = parse_job(job)
        payload['job_status'] = 'deduplicated'
        payload['message'] = "#{base_message(payload)}: deduplicated: #{deduplication_type}"
        payload['deduplication_type'] = deduplication_type

        Sidekiq.logger.info payload
      end
    end
  end
end
