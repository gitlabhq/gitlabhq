# frozen_string_literal: true

module Ci
  class ExpirePipelineCacheWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    urgency :high
    data_consistency :sticky
    deduplicate :until_executed
    idempotent!

    def perform(pipeline_id, options = {})
      Ci::Pipeline.find_by_id_and_partition_id(pipeline_id, options['partition_id']).try do |pipeline|
        Ci::ExpirePipelineCacheService.new.execute(pipeline)
      end
    end
  end
end
