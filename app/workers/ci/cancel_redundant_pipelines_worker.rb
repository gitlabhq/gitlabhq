# frozen_string_literal: true

module Ci
  class CancelRedundantPipelinesWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :continuous_integration
    idempotent!
    deduplicate :until_executed
    urgency :high

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::PipelineCreation::CancelRedundantPipelinesService
          .new(pipeline)
          .execute
      end
    end
  end
end
