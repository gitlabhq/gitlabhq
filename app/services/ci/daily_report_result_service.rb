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

      aggregate(pipeline.builds.with_coverage).map do |group_name, group|
        base_attrs.merge(
          title: group_name,
          value: average_coverage(group)
        )
      end
    end

    def aggregate(builds)
      builds.group_by(&:group_name)
    end

    def average_coverage(group)
      total_coverage = group.reduce(0.0) { |sum, build| sum + build.coverage }
      (total_coverage / group.size).round(2)
    end
  end
end
