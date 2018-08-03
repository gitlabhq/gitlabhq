# frozen_string_literal: true

module Ci
  class CompareTestReportsService < ::BaseService
    def execute(base_pipeline_iid, head_pipeline_iid)
      base_pipeline = project.pipelines.find_by_iid(base_pipeline_iid) if base_pipeline_iid
      head_pipeline = project.pipelines.find_by_iid(head_pipeline_iid)

      begin  
        comparer = Gitlab::Ci::Reports::TestReportsComparer
          .new(base_pipeline&.test_reports, head_pipeline.test_reports)
  
        {
          status: :parsed,
          data: TestReportsComparerSerializer
            .new(project: project)
            .represent(comparer).as_json
        }
      rescue => e
        { status: :error, status_reason: e.message }
      end
    end
  end
end
