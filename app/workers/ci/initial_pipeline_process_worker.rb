# frozen_string_literal: true

module Ci
  class InitialPipelineProcessWorker
    include ApplicationWorker

    # Reads the CI database from the primary, as PipelineProcessWorker does: a stale replica read of the
    # just-inserted jobs strands the pipeline in `created` because the service never reschedules.
    data_consistency :always, overrides: { main: :sticky } # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- see comment above
    sidekiq_options retry: 3
    queue_namespace :pipeline_processing
    feature_category :continuous_integration
    urgency :high
    loggable_arguments 1
    idempotent!

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::PipelineCreation::StartPipelineService
          .new(pipeline)
          .execute
      end
    end
  end
end
