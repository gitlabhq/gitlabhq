# frozen_string_literal: true

module Ci
  class DailyReportResultService
    def execute(pipeline)
      return unless Feature.enabled?(:ci_daily_code_coverage, pipeline.project, default_enabled: true)

      DailyReportResult.upsert_reports(coverage_reports(pipeline))
    end

    private

    def coverage_reports(pipeline)
      base_attrs = {
        project_id: pipeline.project_id,
        ref_path: pipeline.source_ref_path,
        param_type: DailyReportResult.param_types[:coverage],
        date: pipeline.created_at.to_date,
        last_pipeline_id: pipeline.id
      }

      pipeline.builds.with_coverage.map do |build|
        base_attrs.merge(
          title: build.group_name,
          value: build.coverage
        )
      end
    end
  end
end
