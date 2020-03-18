# frozen_string_literal: true

module Ci
  class DailyReportResultsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::DailyReportResultService.new.execute(pipeline)
      end
    end
  end
end
