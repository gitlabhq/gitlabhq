# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    feature_category :code_testing

    idempotent!

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::DailyBuildGroupReportResultService.new.execute(pipeline)
      end
    end
  end
end
