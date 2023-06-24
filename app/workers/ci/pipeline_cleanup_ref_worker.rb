# frozen_string_literal: true

module Ci
  class PipelineCleanupRefWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    sidekiq_options retry: 3
    include PipelineQueue

    LOCK_RETRY = 3
    LOCK_TTL = 5.minutes
    LOCK_SLEEP = 0.5.seconds

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: 1.minute
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

    urgency :low

    # Even though this worker is de-duplicated we need to acquire lock
    # on a project to avoid running many concurrent refs removals
    #
    # TODO: Once underlying fix is done we can remove `in_lock`
    #
    # Related to:
    # - https://gitlab.com/gitlab-org/gitaly/-/issues/5368
    # - https://gitlab.com/gitlab-org/gitaly/-/issues/5369
    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline
      return unless pipeline.persistent_ref.should_delete?

      in_lock("#{self.class.name.underscore}/#{pipeline.project_id}", **lock_params) do
        pipeline.reset.persistent_ref.delete
      end
    end

    private

    def lock_params
      {
        ttl: LOCK_TTL,
        retries: LOCK_RETRY,
        sleep_sec: LOCK_SLEEP
      }
    end
  end
end
