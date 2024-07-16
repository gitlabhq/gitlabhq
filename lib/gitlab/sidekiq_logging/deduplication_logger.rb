# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class DeduplicationLogger
      include Singleton
      include LogsJobs

      def deduplicated_log(job, deduplication_type, deduplication_options = {})
        payload = parse_job(job)
        payload['job_status'] = 'deduplicated'
        payload['message'] = "#{base_message(payload)}: deduplicated: #{deduplication_type}"
        payload['deduplication.type'] = deduplication_type
        # removing nil values from deduplication options
        payload.merge!(
          deduplication_options.compact.transform_keys { |k| "deduplication.options.#{k}" })

        Sidekiq.logger.info payload
      end

      def rescheduled_log(job)
        payload = parse_job(job)
        payload['job_status'] = 'rescheduled'
        payload['message'] = "#{base_message(payload)}: rescheduled"

        Sidekiq.logger.info payload
      end
    end
  end
end
