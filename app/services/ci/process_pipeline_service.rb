# frozen_string_literal: true

module Ci
  class ProcessPipelineService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      increment_processing_counter

      Ci::PipelineProcessing::AtomicProcessingService
        .new(pipeline)
        .execute
    end

    def metrics
      @metrics ||= ::Gitlab::Ci::Pipeline::Metrics
    end

    private

    def increment_processing_counter
      metrics.pipeline_processing_events_counter.increment
    end
  end
end
