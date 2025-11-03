# frozen_string_literal: true

module Ci
  class RetryStuckWaitingJobWorker
    include ApplicationWorker

    # Do not execute (in fact, don't even enqueue) another instance of
    # this Worker with the same args.
    deduplicate :until_executed, including_scheduled: true
    data_consistency :sticky
    idempotent!

    feature_category :continuous_integration

    RETRY_TIMEOUT = 30

    def perform(build_id)
      build = Ci::Build.find_by_id(build_id)

      RetryWaitingJobService.new(build).execute.tap do |result|
        log_extra_metadata_on_done(:message, result.message) if result.message

        if result.error? && result.payload[:reason] == :not_finished_waiting
          # If job is still waiting for runner ack (meaning runner is taking longer than expected to provision,
          # but still actively sending a heartbeat), then let's reschedule this job.
          self.class.perform_in(RETRY_TIMEOUT, build_id)
        end
      end
    end
  end
end
