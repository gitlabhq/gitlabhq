# frozen_string_literal: true

module Ci
  class InitialPipelineProcessWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineQueue

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
