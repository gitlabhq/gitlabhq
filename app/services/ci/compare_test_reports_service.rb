# frozen_string_literal: true

module Ci
  class CompareTestReportsService < ::BaseService
    def execute(base_pipeline, head_pipeline)
      comparer = Gitlab::Ci::Reports::TestReportsComparer
        .new(base_pipeline&.test_reports, head_pipeline.test_reports)

      {
        status: :parsed,
        key: key(base_pipeline, head_pipeline),
        data: TestReportsComparerSerializer
          .new(project: project)
          .represent(comparer).as_json
      }
    rescue => e
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: e.message
      }
    end

    def latest?(base_pipeline, head_pipeline, data)
      data&.fetch(:key, nil) == key(base_pipeline, head_pipeline)
    end

    private

    def key(base_pipeline, head_pipeline)
      [
        base_pipeline&.id, base_pipeline&.updated_at,
        head_pipeline&.id, head_pipeline&.updated_at
      ]
    end
  end
end
