# frozen_string_literal: true

module Ci
  class CancelRedundantPipelinesWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :continuous_integration
    idempotent!
    deduplicate :until_executed
    urgency :low

    def perform(pipeline_id, options = {})
      relation = Ci::Pipeline.all
      relation = relation.in_partition(options['partition_id']) if options['partition_id'].present?

      relation.find_by_id(pipeline_id).try do |pipeline|
        Ci::PipelineCreation::CancelRedundantPipelinesService.new(pipeline).execute
      end
    end
  end
end
