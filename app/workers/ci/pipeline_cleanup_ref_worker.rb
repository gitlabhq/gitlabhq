# frozen_string_literal: true

module Ci
  class PipelineCleanupRefWorker
    include ApplicationWorker
    include Projects::RemoveRefs

    sidekiq_options retry: 3
    include PipelineQueue

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: 1.minute
    data_consistency :always

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

      serialized_remove_refs(pipeline.project_id) do
        pipeline.reset.persistent_ref.delete
      end
    end
  end
end
